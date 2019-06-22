import Path_swift

class HydrusFile {
    let hash: String
    let hashId: Int

    var database: HydrusDatabase
    var metadata: HydrusMetadata

    enum PathType: String {
        case original = "f"
        case thumbnail = "t"
    }

    init(hash: String, hashId: Int, database: HydrusDatabase, metadata: HydrusMetadata) {
        self.hash = hash
        self.hashId = hashId
        self.database = database
        self.metadata = metadata
    }

    func path(type: PathType = .original) -> Path {
        let firstTwo = self.hash[...self.hash.index(hash.startIndex, offsetBy: 1)]
        let sectorId = type.rawValue + firstTwo
        let sectorPath = self.database.databasePath / "client_files" / sectorId

        switch type {
        case .thumbnail:
            return sectorPath / "\(self.hash).thumbnail"
        case .original:
            let mimeExtension = self.metadata.mime.extension()
            return sectorPath / "\(self.hash).\(mimeExtension)"
        }
    }

    func tags() throws -> [HydrusTag] {
        return try self.database.withReadAll({ dbs in
            return try self.database.tags.tags(
                mappingDatabase: dbs[.mapping]!,
                masterDatabase: dbs[.master]!,
                file: self
            )
        })
    }
}
