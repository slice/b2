import Foundation

/// A dummy booru that returns an empty array for all requests.
class NoneBooru: Booru {
  let id = UUID()

  let name = "None"

  let supportedPaginationTypes: [BooruPaginationType] = [.none]

  func search(
    forTags _: [String], offsetBy _: BooruQueryOffset,
    completionHandler: @escaping (Result<[BooruPost], Error>) -> Void
  ) {
    completionHandler(.success([]))
  }
}
