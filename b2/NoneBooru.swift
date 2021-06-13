import Foundation

/// A dummy booru that returns an empty array for all requests.
class NoneBooru: Booru {
    func search(forTags tags: [String], completionHandler: @escaping (Result<[BooruFile], Error>) -> Void) {
        completionHandler(.success([]))
    }
}
