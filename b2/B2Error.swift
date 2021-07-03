import Foundation

enum B2Error: Int {
  case queryFailed
  case invalidBooruEndpoint
  case invalidBooruCredentials
  case previewLoadFailed

  func wrap(underlyingError: Error) -> NSError {
    let userInfo = self.errorUserInfo.merging([NSUnderlyingErrorKey: underlyingError as Any], uniquingKeysWith: { $1 })
    return NSError(domain: Self.errorDomain, code: self.rawValue, userInfo: userInfo)
  }
}

extension B2Error: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .queryFailed: return "Couldn't load posts from the booru."
    case .invalidBooruEndpoint: return "Couldn't connect to the booru."
    case .invalidBooruCredentials: return "Couldn't authenticate with the booru."
    case .previewLoadFailed: return "Couldn't load the image."
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .queryFailed: return "Try making the query again."
    case .invalidBooruEndpoint: return "Make sure that the booru's URL is correct."
    case .invalidBooruCredentials: return "Couldn't authenticate with the booru."
    case .previewLoadFailed: return "Make sure your booru credentials are correct, or try loading the image again."
    }
  }
}

extension B2Error: CustomNSError {
  static var errorDomain: String = "zone.slice.b2.ErrorDomain"

  var errorCode: Int {
    self.rawValue
  }

  var errorUserInfo: [String: Any] {
    [NSLocalizedDescriptionKey: self.errorDescription as Any,
     NSLocalizedRecoverySuggestionErrorKey: self.recoverySuggestion as Any]
  }
}
