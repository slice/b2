import Foundation

/// A tag describes a quality of an image.
public protocol BooruTag: CustomStringConvertible {
  /// The namespace as text.
  var namespace: String? { get }

  /// The subtag as text.
  var subtag: String { get }
}

public struct SimpleBooruTag: BooruTag {
  public var namespace: String?
  public var subtag: String

  init?(parsingDescription description: String) {
    guard description.contains(":") else {
      self.namespace = nil
      self.subtag = description
      return
    }

    let components = description.split(separator: ":", maxSplits: 2)
    self.namespace = String(components[0])
    self.subtag = String(components[1])
  }
}

public extension BooruTag {
  var description: String {
    if let namespace = self.namespace {
      return "\(namespace):\(self.subtag)"
    } else {
      return self.subtag
    }
  }
}
