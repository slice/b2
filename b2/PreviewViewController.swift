import Cocoa
import Combine

class PreviewViewController: NSViewController {
  @IBOutlet var imageView: NSImageView!
  @IBOutlet var progressIndicator: NSProgressIndicator!

  private let loadingQueue = DispatchQueue(label: "loading-queue", qos: .userInitiated)
  var loadingSinks: Set<AnyCancellable> = Set()

  func loadPreviewImage(at url: URL) {
    // Cancel any active loads.
    self.loadingSinks.forEach { $0.cancel() }

    self.imageView.image = nil
    self.progressIndicator.startAnimation(nil)

    let cache = ImageCache.sharedFullImageCache
    let globalID = url.absoluteString

    let publisher: AnyPublisher<NSImage, Error>
    if let cachedImage = cache.image(forGlobalID: globalID) {
      publisher = Just(cachedImage)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    } else {
      publisher = URLSession.shared.dataTaskPublisher(for: url)
        .map(\.data)
        .flatMap { NSImage(data: $0).publisher }
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }

    publisher
      .subscribe(on: self.loadingQueue)
      .receive(on: DispatchQueue.main)
      .catch { error -> Empty<NSImage, Never> in
        self.presentError(error)
        return Empty()
      }
      .sink { image in
        cache.insert(image, forGlobalID: globalID)
        self.imageView.image = image
        self.progressIndicator.stopAnimation(nil)
      }
      .store(in: &self.loadingSinks)
  }
}
