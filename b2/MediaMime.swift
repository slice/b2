import Foundation

enum MediaMime: Int {
    case jpeg = 1
    case png
    case gif
    case bmp
    case flash
    case yaml
    case icon
    case html
    case flv
    case pdf
    case zip
    case hydrusEncryptedZip
    case mp3
    case mp4
    case ogg
    case flac
    case wma
    case wmv
    case undeterminedWindowsMedia
    case mkv
    case webm
    case json
    case apng
    case undeterminedPng
    case mpeg
    case mov
    case avi
    case hydrusUpdateDefinitions
    case hydrusUpdateContent
    case txt
    case rar
    case archive7zip
    case webp
    case tiff
    case psd
    case octetStream = 100
    case unknown = 101

    func `extension`() -> String {
        switch self {
        case .jpeg:
            return "jpg"
        case .png:
            return "png"
        case .gif:
            return "gif"
        case .webm:
            return "webm"
        default:
            NSLog("Warning: Unknown file extension for \(self)")
            return ".unknown"
        }
    }
}
