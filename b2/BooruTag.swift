import Foundation

/// A tag describes a quality of an image.
protocol BooruTag: CustomStringConvertible {
    /// The namespace as text.
    var namespace: String? { get }

    /// The subtag as text.
    var subtag: String { get }

}

extension BooruTag {
    var description: String {
        if let namespace = self.namespace {
            return "\(namespace):\(self.subtag)"
        } else {
            return self.subtag
        }
    }
}
