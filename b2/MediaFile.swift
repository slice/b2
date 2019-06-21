class MediaFile {
    let hash: String
    var database: MediaDatabase?

    init(hash: String, database: MediaDatabase?) {
        self.database = database
        self.hash = hash
    }

    convenience init(hash: String) {
        self.init(hash: hash, database: nil)
    }
}
