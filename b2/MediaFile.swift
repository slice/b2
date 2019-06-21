import Path_swift

class MediaFile {
    let hash: String
    let hashId: Int

    var database: MediaDatabase
    var metadata: MediaMetadata

    enum PathType: String {
        case original = "f"
        case thumbnail = "t"
    }

    init(hash: String, hashId: Int, database: MediaDatabase, metadata: MediaMetadata) {
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

    func tags() throws -> [Tag] {
        return try self.database.tags.tags(forFile: self)
    }
}
