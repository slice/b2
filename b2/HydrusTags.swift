import GRDB

class HydrusTags {
    unowned let database: HydrusDatabase

    var namespaces: [HydrusTagNamespace]!
    var namespacesById: [Int: HydrusTagNamespace]!

    init(database: HydrusDatabase) {
        self.database = database
    }

    /// Caches all namespaces from the master database.
    func cacheNamespaces() throws {
        self.namespaces = try self.database.masterDatabase.read { db in
            return try HydrusTagNamespace.fetchAll(db)
        }

        self.namespacesById = Dictionary(
            uniqueKeysWithValues: self.namespaces.map({ ($0.id, $0) })
        )
    }

    /// Fetches a `Tag` object from a tag ID from the master database.
    func tag(masterDatabase db: Database, id: Int) throws -> HydrusTag {
        let tagRow = try Row.fetchOne(db, sql: "SELECT namespace_id, subtag_id FROM tags WHERE tag_id = ?", arguments: [id])!
        let subtagId = tagRow["subtag_id"] as Int
        let namespaceId = tagRow["namespace_id"] as Int

        let subtag = try HydrusSubtag
            .filter(HydrusSubtag.Columns.id == subtagId)
            .fetchOne(db)!

        var namespace: HydrusTagNamespace
        if let namespacesById = self.namespacesById {
            // Use cached namespace.
            namespace = namespacesById[namespaceId]!
        } else {
            namespace = try HydrusTagNamespace
                .filter(HydrusTagNamespace.Columns.id == namespaceId)
                .fetchOne(db)!
        }

        return HydrusTag(id: id, subtag: subtag, namespace: namespace)
    }

    /// Fetches a file's tags from the databases.
    func tags(mappingDatabase: Database, masterDatabase: Database, file: HydrusFile) throws -> [HydrusTag] {
        let cursor = try Row.fetchCursor(
            mappingDatabase,
            sql: "SELECT tag_id FROM current_mappings_5 WHERE hash_id = ?",
            arguments: [file.hashId]
        )

        return try Array(cursor.map { row in
            return try self.tag(masterDatabase: masterDatabase, id: row["tag_id"] as Int)
        })
    }
}
