import Foundation

struct B2Error {
  public static let domain = "zone.slice.b2.ErrorDomain"

  public enum Code: Int {
    case queryFailed
    case invalidBooruEndpoint
    case invalidBooruCredentials
    case previewLoadFailed
  }

  public static func error(code: Self.Code, userInfo: [String: Any]? = nil) -> NSError {
    NSError(domain: Self.domain, code: code.rawValue, userInfo: userInfo)
  }

  public static func setupUserInfoValueProvider() {
    NSError.setUserInfoValueProvider(forDomain: B2Error.domain) { (error: Error, key) -> Any? in
      let error = error as NSError
      guard let errorCode = B2Error.Code(rawValue: error.code) else {
        return error.userInfo[key]
      }

      func underlyingError() -> NSError {
        guard let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError else {
          fatalError("error didn't supply an underlying error when one was required")
        }
        return underlyingError
      }

      switch errorCode {
      case .queryFailed:
        switch key {
        case NSLocalizedDescriptionKey:
          return "Couldn't load posts from the booru."
        case NSLocalizedRecoverySuggestionErrorKey:
          return "\(underlyingError().localizedDescription) Try making the query again."
        default: return nil
        }
      case .invalidBooruEndpoint:
        switch key {
        case NSLocalizedDescriptionKey:
          return "Couldn't connect to the booru."
        case NSLocalizedRecoverySuggestionErrorKey:
          return "Make sure that the booru's URL is correct."
        default: return nil
        }
      case .invalidBooruCredentials:
        switch key {
        case NSLocalizedDescriptionKey:
          return "Couldn't authenticate with the booru."
        case NSLocalizedRecoverySuggestionErrorKey:
          return
            "Make sure that any passwords and access keys associated with the booru are correct."
        default: return nil
        }
      case .previewLoadFailed:
        switch key {
        case NSLocalizedDescriptionKey:
          return "Couldn't load preview image."
        case NSLocalizedRecoverySuggestionErrorKey:
          return "\(underlyingError().localizedDescription) "
            + "Make sure your booru credentials are correct, or try loading the image again."
        default: return nil
        }
      }
    }
  }
}
