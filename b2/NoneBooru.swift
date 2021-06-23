import Foundation

/// A dummy booru that returns an empty array for all requests.
class NoneBooru: Booru {
    let supportedPaginationTypes: [BooruPaginationType] = [.none]

    func search(forTags tags: [String], offsetBy offset: BooruQueryOffset, completionHandler: @escaping (Result<[BooruFile], Error>) -> Void) {
        completionHandler(.success([]))
    }
}
