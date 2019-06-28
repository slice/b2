import Foundation

/// An imageboard where images are categorized by tags.
protocol Booru {
    /// Returns an array of initial files to display by default.
    func initialFiles() throws -> [BooruFile]

    /// Returns an array of files that have all of the specified tags.
    func search(forFilesWithTags tags: [String]) throws -> [BooruFile]
}
