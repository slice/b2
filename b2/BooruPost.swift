import Cocoa
import Foundation

/// A post in a booru.
public protocol BooruPost {
  /// The URL to the full-resolution image of this post.
  var imageURL: URL { get }

  /// The URL to the thumbnail image of this post.
  var thumbnailImageURL: URL { get }

  /// A booru-local identifier.
  var id: Int { get }

  /// A globally unique identifier for this file.
  var globalID: String { get }

  /// The `Date` that this post was created at.
  var createdAt: Date { get }

  /// The size of the full-resolution image in bytes.
  var size: Int { get }

  /// The tags associated with the post.
  var tags: [BooruTag] { get }

  /// The MIME type of the full-resolution image.
  var mime: BooruMime { get }
}

extension BooruPost {
  var thumbnailImageURL: URL {
    return self.imageURL
  }
}
