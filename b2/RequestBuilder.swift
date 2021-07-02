import Foundation

class RequestBuilder {
  var url: URL
  private var queryItems: [URLQueryItem] = []
  private var pathComponents: [String] = []
  private var headers: [String: String] = [:]

  init(url: URL) {
    self.url = url
  }

  @discardableResult func appendPath(component: String) -> Self {
    self.pathComponents.append(component)
    return self
  }

  @discardableResult func header(name: String, value: String) -> Self {
    self.headers[name] = value
    return self
  }

  @discardableResult func query(name: String, value: String) -> Self {
    let query = URLQueryItem(name: name, value: value)
    self.queryItems.append(query)
    return self
  }

  func build() -> URLRequest? {
    var url = self.url

    for pathComponent in self.pathComponents {
      url = url.appendingPathComponent(pathComponent)
    }

    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return nil
    }
    components.queryItems = self.queryItems

    guard let finalURL = components.url else {
      return nil
    }
    var request = URLRequest(url: finalURL)
    for (name, value) in self.headers {
      request.addValue(value, forHTTPHeaderField: name)
    }

    return request
  }
}
