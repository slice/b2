import Cocoa
import os.log

class ImageCache: NSObject, NSCacheDelegate {
  static let sharedThumbnailCache = ImageCache()
  static let sharedFullImageCache = ImageCache()

  var cache: NSCache<NSString, NSImage> = NSCache()
  private let log = Logger(subsystem: loggingSubsystem, category: "image-cache")

  override init() {
    super.init()
    self.cache.delegate = self
  }

  internal func cache(_: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
    let image = obj as! NSImage
    self.log.info("\(image) will be evicted")
  }

  func image(forGlobalID id: String) -> NSImage? {
    self.cache.object(forKey: NSString(string: id))
  }

  func insert(_ image: NSImage, forGlobalID id: String) {
    self.log.info("inserting image (id: \(id)) into cache")
    self.cache.setObject(image, forKey: NSString(string: id))
  }

  deinit {
    self.log.info("\(self) deinit")
  }
}
