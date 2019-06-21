import Foundation
import SQLite
import Path_swift

// @@ services table
let servicesTable = Table("services")
let services__id = Expression<Int>("service_id")
let services__key = Expression<SQLite.Blob>("service_key")
let services__type = Expression<Int>("service_type")
let services__name = Expression<String>("name")

// @@ current_files table
let currentFilesTable = Table("current_files")
let currentFiles__serviceId = Expression<Int>("service_id")
let currentFiles__hashId = Expression<Int>("hash_id")
let currentFiles__timestamp = Expression<Int>("timestamp")

// @@ hashes table
let hashesTable = Table("hashes")
let hashesTable__hashId = Expression<Int>("hash_id")
let hashesTable__hash = Expression<SQLite.Blob>("hash")

// @@ files_info table
let filesInfoTable = Table("files_info")
let filesInfo__hashId = Expression<Int>("hash_id")
let filesInfo__size = Expression<Int>("size")
let filesInfo__mime = Expression<Int>("mime")
let filesInfo__width = Expression<Int?>("width")
let filesInfo__height = Expression<Int?>("height")

class MediaDatabase {
    var databasePath: Path

    var database: Connection!
    var mappingDatabase: Connection!
    var masterDatabase: Connection!
    var cachesDatabase: Connection!

    var tags: Tags!

    init(databasePath path: Path) throws {
        self.databasePath = path

        func connect(_ file: String) throws -> Connection {
            let databaseFilePath = path / file
            return try Connection(databaseFilePath.string)
        }

        NSLog("Loading database at \(path.string)")
        self.database = try connect("client.db")
        self.mappingDatabase = try connect("client.mappings.db")
        self.masterDatabase = try connect("client.master.db")
        self.cachesDatabase = try connect("client.caches.db")

        self.tags = Tags(database: self)
        try self.tags.load()
    }

    func fetchMetadata(withHashId hashId: Int, timestamp: Int) throws -> MediaMetadata? {
        let query = filesInfoTable.filter(filesInfo__hashId == hashId)
        let row = try self.database.pluck(query)
        if let row = row, let mime = MediaMime(rawValue: row[filesInfo__mime]) {
            return MediaMetadata(
                mime: mime,
                size: row[filesInfo__size],
                width: row[filesInfo__width],
                height: row[filesInfo__height],
                timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp))
            )
        } else {
            return nil
        }
    }

    func resolveServiceId(fromName name: String) throws -> Int? {
        let query = servicesTable.select(services__id).filter(services__name == "all local files")
        let row = try self.database.pluck(query)
        return row == nil ? nil : row![services__id]
    }

    func resolveHash(withId: Int) throws -> String? {
        let query = hashesTable.select(hashesTable__hash).filter(hashesTable__hashId == withId)
        let row = try self.masterDatabase.pluck(query)!
        return row[hashesTable__hash].toHex()
    }

    func media() throws -> [MediaFile] {
        let localFilesServiceId = try self.resolveServiceId(fromName: "all local files")!
        let query = currentFilesTable.filter(currentFiles__serviceId == localFilesServiceId)

        return try (try self.database.prepare(query)).map({ row in
            let hashId = row[currentFiles__hashId]
            let hash = try self.resolveHash(withId: hashId)!
            let metadata = try self.fetchMetadata(withHashId: hashId, timestamp: row[currentFiles__timestamp])
            return MediaFile(hash: hash, hashId: hashId, database: self, metadata: metadata!)
        }).filter({ $0.metadata.mime.isImage() })
    }

    deinit {
        NSLog("Database deinitializing")
    }
}
