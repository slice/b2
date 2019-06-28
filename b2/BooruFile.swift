import Foundation
import Cocoa

/// A file in a booru.
protocol BooruFile {
    /// The URL for this file.
    var imageURL: URL { get }

    /// The URL for the thumbnail image of this file.
    var thumbnailImageURL: URL { get }

    /// An identifier for this file.
    var id: Int { get }

    /// The `Date` that this file was created at.
    var createdAt: Date { get }

    /// The size of this file in bytes.
    var size: Int { get }

    /// The tags associated with this file.
    var tags: [BooruTag] { get }

    /// The MIME type of this file.
    var mime: BooruMime { get }
}

extension BooruFile {
    var thumbnailImageURL: URL {
        return self.imageURL
    }
}
