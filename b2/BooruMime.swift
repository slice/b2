/// An enumeration representing the MIME type of a file.
public enum BooruMime: String {
  case png = "image/png"
  case jpeg = "image/jpeg"
  case webp = "image/webp"
  case gif = "image/gif"

  case webm = "video/webm"
  case mp4 = "video/mp4"
  case swf = "application/x-shockwave-flash"

  var isImage: Bool {
    switch self {
    case .png, .jpeg, .webp, .gif:
      return true
    default:
      return false
    }
  }
}
