import Path_swift

class MediaFile {
    let hash: String
    var database: MediaDatabase
    var metadata: MediaMetadata

    enum PathType: String {
        case original = "f"
        case thumbnail = "t"
    }

    init(hash: String, database: MediaDatabase, metadata: MediaMetadata) {
        self.hash = hash
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
}
