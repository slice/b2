import Foundation

public enum BooruPaginationType: Comparable {
  /// Pagination does not occur at all.
  case none

  /// Pagination occurs with incrementing page numbers.
  case pages

  /// Pagination occurs by providing the lowest ID of the previous chunk.
  case relativeToLowestPreviousID
}

/// The offset that posts should be loaded relative to whenever making a fetch.
/// This is essential for pagination purposes, e.g. loading "more" posts from an
/// existing collection of posts.
public enum BooruQueryOffset {
  case none
  case pageNumber(Int)
  case previousChunk([BooruPost])
}

/// An imageboard where images are categorized by tags.
public protocol Booru: AnyObject {
  /// The identifier for the instance of this booru.
  var id: UUID { get }

  /// The name of this booru.
  var name: String { get }

  /// The name as it should be presented to the user.
  var humanName: String { get }

  /// The supported pagination types of this booru, which determines how the
  /// booru handles query offsets.
  var supportedPaginationTypes: [BooruPaginationType] { get }

  /// Fetches an initial set of posts to display by default.
  func initialFiles(completionHandler: @escaping (Result<[BooruPost], Error>) -> Void)

  /// Fetches all posts with the specified tags, offset by a pagination query.
  func search(
    forTags tags: [String], offsetBy: BooruQueryOffset,
    completionHandler: @escaping (Result<[BooruPost], Error>) -> Void)

  /// Fetches all posts with the specified tags.
  func search(
    forTags tags: [String], completionHandler: @escaping (Result<[BooruPost], Error>) -> Void)
}

extension Booru {
  var humanName: String {
    self.name
  }

  func initialFiles(completionHandler: @escaping (Result<[BooruPost], Error>) -> Void) {
    self.search(forTags: [], completionHandler: completionHandler)
  }

  func search(
    forTags tags: [String], completionHandler: @escaping (Result<[BooruPost], Error>) -> Void
  ) {
    var queryOffset: BooruQueryOffset = .none

    if self.supportedPaginationTypes.contains(.pages) {
      queryOffset = .pageNumber(0)
    } else if self.supportedPaginationTypes.contains(.relativeToLowestPreviousID) {
      queryOffset = .previousChunk([])
    }

    self.search(forTags: tags, offsetBy: queryOffset, completionHandler: completionHandler)
  }

  func formGlobalID(withBooruID id: Int) -> String {
    return "\(self.id).\(id)"
  }
}
