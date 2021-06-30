/// An enumeration representing the MIME type of a file.
public enum BooruMime: String {
  // Images:
  case png = "image/png"
  case jpeg = "image/jpeg"
  case webp = "image/webp"
  case gif = "image/gif"

  // Videos and interactive media:
  case webm = "video/webm"
  case mp4 = "video/mp4"
  case swf = "application/x-shockwave-flash"

  /// Return the corresponding `BooruMime` from a file extension.
  init?(extension: String) {
    switch `extension` {
    case "png": self = .png
    case "jpg": self = .jpeg
    case "jpeg": self = .jpeg
    case "gif": self = .gif
    case "webm": self = .webm
    case "swf": self = .swf
    default: return nil
    }
  }

  var isImage: Bool {
    switch self {
    case .png, .jpeg, .webp, .gif:
      return true
    default:
      return false
    }
  }
}
