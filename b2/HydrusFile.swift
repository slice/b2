import Path_swift

/// A file in a Hydrus database.
class HydrusFile {
    fileprivate enum PathType: String {
        case original = "f"
        case thumbnail = "t"
    }

    /// The hash of the file as a hexadecimal string.
    let hash: String

    /// The ID of the hash of the file in the database.
    let hashId: Int

    /// An unowned reference to the `HydrusDatabase`.
    unowned var database: HydrusDatabase

    /// The file's metadata.
    private var metadata: HydrusMetadata

    lazy fileprivate var cachedTags: [HydrusTag] = {
        return try! measure("Initial Hydrus tag fetch for \(self.hashId)") {
            return try self.fetchTags()
        }
    }()

    init(hash: String, hashId: Int, database: HydrusDatabase, metadata: HydrusMetadata) {
        self.hash = hash
        self.hashId = hashId
        self.database = database
        self.metadata = metadata
    }

    fileprivate func path(ofType type: PathType = .original) -> Path {
        let firstTwo = self.hash[...self.hash.index(hash.startIndex, offsetBy: 1)]
        let sectorId = type.rawValue + firstTwo
        let sectorPath = self.database.databasePath / "client_files" / sectorId

        switch type {
        case .thumbnail:
            return sectorPath / "\(self.hash).thumbnail"
        case .original:
            let ext = self.metadata.mime.extension
            return sectorPath / "\(self.hash).\(ext)"
        }
    }

    fileprivate func fetchTags() throws -> [HydrusTag] {
        return try self.database.withReadAll({ dbs in
            return try self.database.tags.tags(
                mappingDatabase: dbs[.mapping]!,
                masterDatabase: dbs[.master]!,
                file: self
            )
        })
    }
}

extension HydrusFile: BooruFile {
    var id: Int {
        return self.hashId
    }

    var imageURL: URL {
        return self.path(ofType: .original).url
    }

    var thumbnailImageURL: URL {
        return self.path(ofType: .thumbnail).url
    }

    var createdAt: Date {
        return self.metadata.timestamp
    }

    var size: Int {
        return self.metadata.size
    }

    var tags: [BooruTag] {
        return self.cachedTags
    }

    var mime: BooruMime {
        return self.metadata.mime.booruMime!
    }
}
