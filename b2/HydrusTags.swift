import GRDB

class HydrusTags {
  unowned let database: HydrusDatabase

  var cachedNamespaces: [HydrusTagNamespace]!
  var cachedNamespacesByID: [Int: HydrusTagNamespace]!

  init(database: HydrusDatabase) {
    self.database = database
  }

  /// Caches all namespaces from the master database.
  func cacheNamespaces() throws {
    self.cachedNamespaces = try self.database.queue.read { db in
      try HydrusTagNamespace.fetchAll(db)
    }

    self.cachedNamespacesByID = Dictionary(
      uniqueKeysWithValues: self.cachedNamespaces.map { ($0.id, $0) }
    )
  }

  /// Fetches a `Tag` object from a tag ID from the master database.
  func tag(fromTagID tagID: Int, database: Database) throws -> HydrusTag {
    let tagRow = try Row.fetchOne(
      database,
      sql: "SELECT namespace_id, subtag_id FROM master.tags WHERE tag_id = ?",
      arguments: [tagID]
    )!

    let subtagID: Int = tagRow["subtag_id"]
    let namespaceID: Int = tagRow["namespace_id"]

    let subtag = try HydrusSubtag.fetchOne(
      database,
      sql: "SELECT subtag_id, subtag FROM master.subtags WHERE subtag_id = ?",
      arguments: [subtagID]
    )!

    var namespace: HydrusTagNamespace

    // If we've cached the namespaces
    if let cachedNamespaces = self.cachedNamespacesByID {
      // Use cached namespace.
      namespace = cachedNamespaces[namespaceID]!
    } else {
      namespace = try HydrusTagNamespace.fetchOne(
        database,
        sql: "SELECT namespace_id, namespace FROM master.namespaces WHERE namespace_id = ?",
        arguments: [namespaceID]
      )!
    }

    return HydrusTag(id: tagID, subtag: subtag, namespace: namespace)
  }

  /// Fetches a file's tags from the databases.
  func tags(forFile file: HydrusFile, database: Database) throws -> [HydrusTag] {
    guard let localTagsServiceID = self.database.localTagsServiceID else {
      fatalError("can't fetch the tags for a file if we don't have the local tags service id")
    }
    let mappingsTableName = "mappings.current_mappings_\(localTagsServiceID)"
    let cursor = try Row.fetchCursor(
      database,
      sql: "SELECT tag_id FROM \(mappingsTableName) WHERE hash_id = ?",
      arguments: [file.hashId]
    )

    return try Array(
      cursor.map { row in
        try self.tag(fromTagID: row["tag_id"] as Int, database: database)
      })
  }
}
