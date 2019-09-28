import Foundation
import GRDB
import Path

class HydrusDatabase {
    var databasePath: Path

    var database: DatabasePool!
    var mappingDatabase: DatabasePool!
    var masterDatabase: DatabasePool!
    var cachesDatabase: DatabasePool!

    var tags: HydrusTags!

    init(databasePath path: Path) throws {
        self.databasePath = path

        func connect(_ file: String, labeled label: String) throws -> DatabasePool {
            let databaseFilePath = path / file
            var config = Configuration()
            config.label = label
            return try DatabasePool(path: databaseFilePath.string, configuration: config)
        }

        NSLog("Loading database at \(path.string)")
        self.database = try connect("client.db", labeled: "main")
        self.mappingDatabase = try connect("client.mappings.db", labeled: "mappings")
        self.masterDatabase = try connect("client.master.db", labeled: "master")
        self.cachesDatabase = try connect("client.caches.db", labeled: "caches")

        self.tags = HydrusTags(database: self)
        try self.tags.cacheNamespaces()
    }

    enum DatabaseIndex {
        case main
        case master
        case mapping
        case caches
    }

    /// Runs a function with simultaneous read access to all databases.
    func withReadAll<T>(_ block: ([DatabaseIndex: Database]) throws -> T) throws -> T {
        return try self.database.read { main in
            return try self.masterDatabase.read { master in
                return try self.mappingDatabase.read { mapping in
                    return try self.cachesDatabase.read { caches in
                        return try block([
                            .main: main,
                            .master: master,
                            .mapping: mapping,
                            .caches: caches
                        ])
                    }
                }
            }
        }
    }

    /// Fetches a `MediaMetadata` from the main database.
    func fetchMetadata(mainDatabase db: Database, hashId: Int, timestamp: Int) throws -> HydrusMetadata? {
        let row = try Row.fetchOne(db, sql: "SELECT * FROM files_info WHERE hash_id = ?", arguments: [hashId])

        if let row = row, let mime = HydrusMime(rawValue: row["mime"]) {
            return HydrusMetadata(
                mime: mime,
                size: row["size"],
                width: row["width"],
                height: row["height"],
                timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp))
            )
        } else {
            return nil
        }
    }

    /// Fetches a hash's associated timestamp from the main database.
    func fetchTimestamp(mainDatabase db: Database, hashId: Int) throws -> Int? {
        let row = try Row.fetchOne(
            db,
            sql: "SELECT timestamp FROM current_files WHERE hash_id = ?",
            arguments: [hashId]
        )
        return row?["timestamp"]
    }

    /// Fetches a service ID from its name from the main database.
    func fetchServiceId(mainDatabase db: Database, name: String) throws -> Int? {
        let row = try Row.fetchOne(
            db,
            sql: "SELECT service_id FROM services WHERE name = ?",
            arguments: [name]
        )
        return row?["service_id"]
    }

    /// Fetches a hash from its ID from the master database.
    func fetchHash(masterDatabase db: Database, id: Int) throws -> String? {
        let row = try Row.fetchOne(
            db,
            sql: "SELECT hash FROM hashes WHERE hash_id = ?",
            arguments: [id]
        )
        let data = row?["hash"] as? Data
        return data?.hexEncodedString()
    }

    /// Fetches all local files in the "all local files" service from the main and master databases.
    func fetchAllFiles(mainDatabase: Database, masterDatabase: Database) throws -> [HydrusFile] {
        guard let localFilesServiceId = try self.fetchServiceId(mainDatabase: mainDatabase, name: "all local files") else {
            NSLog("Cannot fetch \"all local files\" service.")
            return []
        }

        let sql = "SELECT hash_id, timestamp FROM current_files WHERE service_id = ?"
        let cursor = try Row.fetchCursor(mainDatabase, sql: sql, arguments: [localFilesServiceId])
        return try Array(cursor.map { row in
            let hashId = row["hash_id"] as Int
            let hash = try self.fetchHash(masterDatabase: masterDatabase, id: hashId)!
            let metadata = try self.fetchMetadata(mainDatabase: mainDatabase, hashId: hashId, timestamp: row["timestamp"])!

            guard metadata.mime.booruMime != nil else {
                // MIME type isn't appropriate.
                return nil
            }

            return HydrusFile(hash: hash, hashId: hashId, database: self, metadata: metadata)
        }.compactMap({ $0 }))
    }

    deinit {
        NSLog("Database deinitializing")
    }
}

extension HydrusDatabase: Booru {
    func initialFiles() throws -> [BooruFile] {
        return try self.database.read { db in
            return try self.masterDatabase.read { masterDb in
                return try self.fetchAllFiles(mainDatabase: db, masterDatabase: masterDb)
            }
        }
    }

    func search(forFilesWithTags tags: [String]) throws -> [BooruFile] {
        let cachedTags: [Int?] = try self.cachesDatabase.read { db in
            return try tags.map({ tag in
                return try HydrusCachedTag.filter(HydrusCachedTag.Columns.tag == tag).fetchOne(db)?.id
            })
        }

        // If `nil` is in `cachedTags`, a tag wasn't found.
        if cachedTags.isEmpty || cachedTags.contains(nil) {
            NSLog("Search made with no valid tags.")
            return []
        }

        // Convert type from `[Int?]` to `[Int]`.
        let tagIds = cachedTags.compactMap({ $0 })

        let request = SQLRequest<Any>(literal: """
            SELECT DISTINCT hash_id
            FROM current_mappings_5
            WHERE tag_id IN \(tagIds)
            GROUP BY hash_id
            HAVING COUNT(DISTINCT tag_id) = \(tagIds.count)
        """)

        return try self.withReadAll { dbs in
            let cursor = try Row.fetchCursor(dbs[.mapping]!, request)
            return try Array(cursor.map({ row in
                let hashId = row["hash_id"] as Int
                let hash = try self.fetchHash(masterDatabase: dbs[.master]!, id: hashId)!

                guard let timestamp = try self.fetchTimestamp(mainDatabase: dbs[.main]!, hashId: hashId) else {
                    NSLog("Failed to locate \(hashId) in current_files table.")
                    return nil
                }

                guard let metadata = try self.fetchMetadata(mainDatabase: dbs[.main]!, hashId: hashId, timestamp: timestamp) else {
                    NSLog("Failed to locate \(hashId) in files_info table.")
                    return nil
                }

                return HydrusFile(hash: hash, hashId: hashId, database: self, metadata: metadata)
            })).compactMap({ $0 })
        }
    }
}
