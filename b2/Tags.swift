import SQLite

// client.mappings.db @@ current_mappings_5
let currentMappingsTable = Table("current_mappings_5")
let currentMappings__tagId = Expression<Int>("tag_id")
let currentMappings__hashId = Expression<Int>("hash_id")

// client.master.db @@ tags
let tagsTable = Table("tags")
let tags__tagId = Expression<Int>("tag_id")
let tags__namespaceId = Expression<Int>("namespace_id")
let tags__subtagId = Expression<Int>("subtag_id")

// client.master.db @@ namespaces
let namespacesTable = Table("namespaces")
let namespaces__namespaceId = Expression<Int>("namespace_id")
let namespaces__namespace = Expression<String>("namespace")

// client.master.db @@ subtags
let subtagsTable = Table("subtags")
let subtags__subtagId = Expression<Int>("subtag_id")
let subtags__subtag = Expression<String>("subtag")

class Tags {
    var database: MediaDatabase

    init(database: MediaDatabase) {
        self.database = database
    }

    func resolveTag(withId id: Int) throws -> Tag {
        let tagRow = try self.database.masterDatabase.pluck(
            tagsTable.filter(tags__tagId == id)
        )!

        let subtag = try self.database.masterDatabase.pluck(
            subtagsTable.filter(subtags__subtagId == tagRow[tags__subtagId])
        )![subtags__subtag]

        let namespaceRow = try self.database.masterDatabase.pluck(
            namespacesTable.filter(namespaces__namespaceId == tagRow[tags__namespaceId])
        )!

        if namespaceRow[namespaces__namespace] == "" {
            return Tag(subtag)
        } else {
            let namespace = TagNamespace(
                id: namespaceRow[namespaces__namespaceId],
                namespace: namespaceRow[namespaces__namespace]
            )

            return Tag(subtag, namespace: namespace)
        }
    }

    func tags(forFile file: MediaFile) throws -> [Tag] {
        let query = currentMappingsTable.filter(currentMappings__hashId == file.hashId)
        let mappingRows = try self.database.mappingDatabase.prepare(query)

        return try mappingRows.map({ row in
            let tagId = row[currentMappings__tagId]
            return try self.resolveTag(withId: tagId)
        })
    }
}
