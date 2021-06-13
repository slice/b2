import Foundation

/// An imageboard where images are categorized by tags.
protocol Booru {
    /// Returns an array of initial files to display by default.
    func initialFiles(completionHandler: @escaping (Result<[BooruFile], Error>) -> Void)

    /// Returns an array of files that have all of the specified tags.
    func search(forTags tags: [String], completionHandler: @escaping (Result<[BooruFile], Error>) -> Void)
}

extension Booru {
    func initialFiles(completionHandler: @escaping (Result<[BooruFile], Error>) -> Void) {
        self.search(forTags: [], completionHandler: completionHandler)
    }
}
