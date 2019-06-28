import Foundation

/// A dummy booru that returns an empty array for all requests.
class NoneBooru: Booru {
    func initialFiles() throws -> [BooruFile] {
        return []
    }

    func search(forFilesWithTags tags: [String]) throws -> [BooruFile] {
        return []
    }
}
