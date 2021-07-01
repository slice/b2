import Foundation
import GRDB
import Path

class HydrusDatabase {
  /// The base database folder path.
  ///
  /// This is not a path to any actual database file.
  var base: Path

  /// The GRDB database queue.
  var queue: DatabaseQueue!

  var tags: HydrusTags!

  let supportedPaginationTypes: [BooruPaginationType] = [.none]

  var id = UUID()

  var name: String = "Hydrus"

  /// The service ID of the "local tags" service.
  var localTagsServiceID: Int!

  init(atBasePath basePath: Path) throws {
    self.base = basePath

    NSLog("loading hydrus database (base path: \(basePath))")

    var config = Configuration()
    config.qos = .userInitiated
    self.queue = try DatabaseQueue(path: (basePath / "client.db").string, configuration: config)

    try self.queue.inDatabase { db in
      let mappingsPath = basePath / "client.mappings.db"
      let masterPath = basePath / "client.master.db"
      let cachesPath = basePath / "client.caches.db"

      // Attach additional databases. This is much more ergonomic than
      // having multiple database queues or pools.
      try db.execute(sql: "ATTACH DATABASE '\(mappingsPath.string)' AS mappings")
      try db.execute(sql: "ATTACH DATABASE '\(masterPath.string)' AS master")
      try db.execute(sql: "ATTACH DATABASE '\(cachesPath.string)' AS caches")
    }

    self.tags = HydrusTags(database: self)
    try self.tags.cacheNamespaces()

    try self.queue.read { db in
      guard let localTagsServiceID = try self.discoverLocalTagsServiceID(database: db) else {
        fatalError("failed to discover local tags service ID")
      }

      self.localTagsServiceID = localTagsServiceID
    }
  }

  /// Discovers the service ID for the "local tags" service.
  ///
  /// This is needed because said service ID is a part of the table name of the
  /// main mappings table.
  private func discoverLocalTagsServiceID(database: Database) throws -> Int? {
    let row = try Row.fetchOne(
      database,
      sql: "SELECT service_id FROM services WHERE service_key LIKE '%local tags%'"
    )

    return row?["service_id"]
  }

  /// Fetches a `MediaMetadata` from the main database.
  func fetchMetadataForFile(withHashID hashID: Int, timestamp: Int, database: Database) throws
    -> HydrusMetadata?
  {
    let row = try Row.fetchOne(
      database,
      sql: "SELECT * FROM files_info WHERE hash_id = ?",
      arguments: [hashID]
    )

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
  func fetchTimestampForFile(withHashID hashID: Int, database: Database) throws -> Int? {
    let row = try Row.fetchOne(
      database,
      sql: "SELECT timestamp FROM current_files WHERE hash_id = ?",
      arguments: [hashID]
    )
    return row?["timestamp"]
  }

  /// Fetches a service ID from its name from the main database.
  func fetchServiceID(fromName name: String, database: Database) throws -> Int? {
    let row = try Row.fetchOne(
      database,
      sql: "SELECT service_id FROM services WHERE name = ?",
      arguments: [name]
    )
    return row?["service_id"]
  }

  /// Fetches a hash from its ID from the master database.
  func fetchHash(fromID id: Int, database: Database) throws -> String? {
    let row = try Row.fetchOne(
      database,
      sql: "SELECT hash FROM master.hashes WHERE hash_id = ?",
      arguments: [id]
    )

    let data = row?["hash"] as? Data
    return data?.hexEncodedString()
  }

  /// Fetches all local files in the "all local files" service from the main and master databases.
  func fetchAllFiles() throws -> [HydrusFile] {
    return try self.queue.read { db -> [HydrusFile] in
      guard
        let localFilesServiceId = try self.fetchServiceID(fromName: "all local files", database: db)
      else {
        NSLog("Cannot fetch \"all local files\" service.")
        return []
      }

      // Select all files from the local files service.
      let sql = "SELECT hash_id, timestamp FROM current_files WHERE service_id = ?"
      let cursor = try Row.fetchCursor(db, sql: sql, arguments: [localFilesServiceId])

      // TODO: We shouldn't be making queries in a loop like this; instead
      // we can make one query across the tables.
      return try Array(
        cursor.map { row in
          let hashID = row["hash_id"] as Int
          let hash = try self.fetchHash(fromID: hashID, database: db)!
          let metadata = try self.fetchMetadataForFile(
            withHashID: hashID, timestamp: row["timestamp"], database: db)!

          guard metadata.mime.booruMime != nil else {
            // MIME type isn't appropriate.
            return nil
          }

          let globalID = self.formGlobalID(withBooruID: hashID)
          return HydrusFile(
            hash: hash, hashId: hashID, database: self, metadata: metadata, globalID: globalID)
        }.compactMap({ $0 }))
    }
  }

  deinit {
    NSLog("hydrus database deinitializing")
  }
}

extension HydrusDatabase: Booru {
  func initialFiles(completionHandler: @escaping (Result<[BooruPost], Error>) -> Void) {
    do {
      let files = try self.fetchAllFiles()
      completionHandler(.success(files))
    } catch {
      completionHandler(.failure(error))
    }
  }

  private func performSearch(forTags tags: [String]) throws -> [BooruPost] {
    // Replace underscores with spaces so that we can search for tags with
    // spaces. This means that we can't search for tags with underscores
    // anymore, but it's fairly standard to use spaces in lieu of underscores
    // within Hydrus, so this is probably OK (for now).
    //
    // We should probably use token fields again, sometime later.
    let tags = tags.map { $0.replacingOccurrences(of: "_", with: " ") }

    // Resolve the given tags to their IDs with the cache.
    let cachedTags: [Int?] = try self.queue.read { db in
      return try tags.map({ tag in
        return try HydrusCachedTag.filter(HydrusCachedTag.Columns.tag == tag).fetchOne(db)?.id
      })
    }

    // If `nil` appears in `cachedTags`, then a tag wasn't found.
    if cachedTags.isEmpty || cachedTags.contains(nil) {
      NSLog("Search made with no valid tags.")
      return []
    }

    let tagIDs = cachedTags.compactMap({ $0 })

    // TODO: Figure out how this monster of an SQL query works and document it.
    guard let localTagsServiceID = self.localTagsServiceID else {
      fatalError("can't make a search when we haven't discovered the local tags service id")
    }
    let mappingsTableName = "mappings.current_mappings_\(localTagsServiceID)"
    let request = SQLRequest<Any>(
      literal: """
            SELECT DISTINCT hash_id
            FROM \(sql: mappingsTableName)
            WHERE tag_id IN \(tagIDs)
            GROUP BY hash_id
            HAVING COUNT(DISTINCT tag_id) = \(tagIDs.count)
        """)

    return try self.queue.read { db in
      let cursor = try Row.fetchCursor(db, request)

      return try Array(
        cursor.map({ row in
          let hashID = row["hash_id"] as Int

          guard let hash = try self.fetchHash(fromID: hashID, database: db) else {
            NSLog("Failed to locate hash \(hashID).")
            return nil
          }

          guard let timestamp = try self.fetchTimestampForFile(withHashID: hashID, database: db)
          else {
            NSLog("Failed to locate \(hashID) in current_files table.")
            return nil
          }

          guard
            let metadata = try self.fetchMetadataForFile(
              withHashID: hashID, timestamp: timestamp, database: db)
          else {
            NSLog("Failed to locate \(hashID) in files_info table.")
            return nil
          }

          let globalID = self.formGlobalID(withBooruID: hashID)
          return HydrusFile(
            hash: hash, hashId: hashID, database: self, metadata: metadata, globalID: globalID)
        })
      ).compactMap({ $0 })
    }
  }

  func search(
    forTags tags: [String], offsetBy offset: BooruQueryOffset,
    completionHandler: @escaping (Result<[BooruPost], Error>) -> Void
  ) {
    do {
      let files = try self.performSearch(forTags: tags)
      completionHandler(.success(files))
    } catch {
      completionHandler(.failure(error))
    }
  }
}
