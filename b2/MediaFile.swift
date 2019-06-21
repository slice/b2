class MediaFile {
    let hash: String
    var database: MediaDatabase?

    var path: String {
        let path = self.database!.pathToHash(self.hash).string
        // TODO: Handle other file types instead of assuming PNG
        return path + ".png"
    }

    init(hash: String, database: MediaDatabase?) {
        self.database = database
        self.hash = hash
    }

    convenience init(hash: String) {
        self.init(hash: hash, database: nil)
    }
}
