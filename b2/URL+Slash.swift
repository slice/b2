import Foundation

public extension URL {
  static func / (url: URL, component: String) -> URL {
    url.appendingPathComponent(component)
  }
}
