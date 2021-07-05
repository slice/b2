import Cocoa
import Combine
import os.log

extension NSUserInterfaceItemIdentifier {
  static let postsGridItem = Self(rawValue: "PostsGridCollectionViewItem")
}

class PostsViewController: NSViewController {
  @IBOutlet var collectionView: NSCollectionView!
  @IBOutlet var progressIndicator: NSProgressIndicator!

  /// The listing that this controller is displaying.
  public var listing: BooruListing?

  /// A closure to be called when a new post is selected.
  public var onPostSelected: ((BooruPost) -> Void)?

  /// A closure to be called when scrolling nearly reaches the end of the
  /// listing.
  public let scrolledNearEnd = PassthroughSubject<Void, Never>()

  private var defaultsObserver: AnyCancellable!
  private var scrollViewMagnifyEndObserver: AnyCancellable!
  private var clipViewBoundsChangedObserver: AnyCancellable!

  internal let postsLog = Logger(subsystem: loggingSubsystem, category: "posts")
  internal let fetchLog = Logger(subsystem: loggingSubsystem, category: "fetch")

  /// A `DispatchQueue` used for loading thumbnails.
  internal let thumbnailsQueue = DispatchQueue(label: "thumbnails", attributes: .concurrent)

  /// The diffable data source used for the collection view.
  internal lazy var dataSource: NSCollectionViewDiffableDataSource<PostsGridSection, String> = self.makeDiffableDataSource()

  private var logImageCachingAndFetching: Bool = Preferences.shared.get(.logImageCachingAndFetching)

  override func viewDidLoad() {
    super.viewDidLoad()

    let scrollView = self.collectionView.enclosingScrollView!

    if Preferences.shared.get(.imageGridPinchZoomEnabled) {
      scrollView.allowsMagnification = true

      self.scrollViewMagnifyEndObserver = NotificationCenter.default.publisher(
        for: NSScrollView.didEndLiveMagnifyNotification, object: scrollView
      )
      .sink { [weak self] _ in
        let currentSize: Int = Preferences.shared.get(.imageGridThumbnailSize)
        let newSize = Int(Float(currentSize) * Float(scrollView.magnification))
        self?.postsLog.info(
          "setting image grid thumbnail size to \(newSize) after magnifying to \(scrollView.magnification) (from \(currentSize))"
        )
        Preferences.shared.set(.imageGridThumbnailSize, to: newSize)
        scrollView.magnification = 1
      }
    }

    self.collectionView.collectionViewLayout = self.makeCompositionalLayout()

    self.defaultsObserver = NotificationCenter.default.publisher(for: .preferencesChanged)
      .sink { [weak self] _ in
        self?.collectionView.collectionViewLayout = self?.makeCompositionalLayout()
      }

    let clipView = scrollView.contentView
    clipView.postsBoundsChangedNotifications = true
    self.clipViewBoundsChangedObserver = NotificationCenter.default.publisher(
      for: NSView.boundsDidChangeNotification, object: clipView
    )
    .sink { [weak self] _ in
      self?.loadMoreIfNearEnd(scrollView: scrollView)
    }

    self.setupCollectionView()
  }

  internal func loadMoreIfNearEnd(scrollView: NSScrollView) {
    let clipView = scrollView.contentView
    let documentView = scrollView.documentView!
    //        guard documentView.frame.height > clipView.bounds.height else {
    //            self.postsLog.info("not triggering a fetch due to a bounds change because the grid content doesn't fit within the frame")
    //            return
    //        }
    let percentageScrolled =
      clipView.bounds.origin.y / (documentView.frame.height - clipView.bounds.height)
    if percentageScrolled >= 0.9 {
      self.scrolledNearEnd.send()
    }
  }

  internal func loadFallbackThumbnailData() -> Data {
    guard
      let fallbackImageURL = Bundle.main.url(forResource: "FailedToLoadImage", withExtension: "png")
    else {
      fatalError("failed to locate *fallback* thumbnail image (what)")
    }

    guard let fallbackData = try? Data(contentsOf: fallbackImageURL) else {
      fatalError("failed to load *fallback* thumbnail image data (something terrible has happened)")
    }

    return fallbackData
  }

  internal func loadThumbnail(forPost post: BooruPost) throws -> NSImage {
    let cache = ImageCache.sharedThumbnailCache

    if let image = cache.image(forGlobalID: post.globalID) {
      if self.logImageCachingAndFetching {
        self.fetchLog.debug("using cached thumbnail for post \(post.globalID, privacy: .public)")
      }
      return image
    } else {
      if self.logImageCachingAndFetching {
        self.fetchLog.info("fetching thumbnail for post \(post.globalID, privacy: .public)")
      }

      let data = try Data(contentsOf: post.thumbnailImageURL)
      guard let image = NSImage(data: data) else {
        // TODO: Temporary. Proper errors coming soon™!
        throw NSError(domain: "zone.slice.b2", code: 1001)
      }

      cache.insert(image, forGlobalID: post.globalID)
      return image
    }
  }

  deinit {
    self.postsLog.notice("PostsViewController deinit")
  }
}
