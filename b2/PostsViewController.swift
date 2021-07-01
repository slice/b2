//
//  PostsViewController.swift
//  b2
//
//  Created by slice on 6/6/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa
import Combine
import os.log

extension NSUserInterfaceItemIdentifier {
  static let postsGridItem = Self(rawValue: "PostsGridCollectionViewItem")
}

class PostsViewController: NSViewController {
  @IBOutlet weak var collectionView: NSCollectionView!
  @IBOutlet weak var progressIndicator: NSProgressIndicator!

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

  private let postsLog = Logger(subsystem: loggingSubsystem, category: "posts")
  private let fetchLog = Logger(subsystem: loggingSubsystem, category: "fetch")

  /// A `DispatchQueue` used for loading thumbnails.
  private let thumbnailsQueue = DispatchQueue(label: "thumbnails", attributes: .concurrent)

  private func imageLayerGravity() -> CALayerContentsGravity {
    guard let mode = PostsGridScalingMode(rawValue: Preferences.shared.get(.imageGridScalingMode))
    else {
      fatalError("failed to determine grid scaling mode")
    }

    switch mode {
    case .fill:
      return .resizeAspectFill
    case .resizeToFit:
      return .resizeAspect
    }
  }

  private func updateCollectionViewLayout() {
    let spacing: Int = Preferences.shared.get(.imageGridSpacing)
    let size: Int = Preferences.shared.get(.imageGridThumbnailSize)

    let layout = self.collectionView.collectionViewLayout! as! NSCollectionViewGridLayout
    layout.minimumInteritemSpacing = CGFloat(spacing)
    layout.minimumLineSpacing = CGFloat(spacing)
    layout.minimumItemSize = NSSize(width: size, height: size)
    layout.maximumItemSize = NSSize(width: size, height: size)

    let gravity = self.imageLayerGravity()
    for item in self.collectionView.visibleItems() {
      let item = item as! PostsGridCollectionViewItem
      item.selectableImageView.contentsGravity = gravity
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Let the NSVisualEffectView show through.
    self.collectionView.backgroundColors = [.clear]

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

    self.updateCollectionViewLayout()

    self.defaultsObserver = NotificationCenter.default.publisher(for: .preferencesChanged)
      .sink { [weak self] _ in
        self?.updateCollectionViewLayout()
      }

    let clipView = scrollView.contentView
    clipView.postsBoundsChangedNotifications = true
    self.clipViewBoundsChangedObserver = NotificationCenter.default.publisher(
      for: NSView.boundsDidChangeNotification, object: clipView
    )
    .sink { [weak self] _ in
      self?.loadMoreIfNearEnd(scrollView: scrollView)
    }

    self.collectionView.register(
      PostsGridCollectionViewItem.self, forItemWithIdentifier: .postsGridItem)
  }

  private func loadMoreIfNearEnd(scrollView: NSScrollView) {
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

  private func loadFallbackThumbnailData() -> Data {
    guard let fallbackImageURL = Bundle.main.url(forResource: "FailedToLoadImage", withExtension: "png") else {
      fatalError("failed to locate *fallback* thumbnail image (what)")
    }

    guard let fallbackData = try? Data(contentsOf: fallbackImageURL) else {
      fatalError("failed to load *fallback* thumbnail image data (something terrible has happened)")
    }

    return fallbackData
  }

  private func loadThumbnail(forPost post: BooruPost) throws -> NSImage {
    let cache = ImageCache.shared

    if let image = cache.image(forGlobalID: post.globalID) {
      self.fetchLog.debug("using cached thumbnail for post \(post.globalID, privacy: .public)")
      return image
    } else {
      self.fetchLog.info("fetching thumbnail for post \(post.globalID, privacy: .public)")

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

extension PostsViewController: NSCollectionViewDelegate {
  func collectionView(
    _ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>
  ) {
    let lastIndexPath = indexPaths.max()!
    let item = collectionView.item(at: lastIndexPath) as? PostsGridCollectionViewItem

    if let file = item?.file {
      self.onPostSelected?(file)
    }
  }

  // Only load thumbnails as the user scrolls.
  func collectionView(
    _ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem,
    forRepresentedObjectAt indexPath: IndexPath
  ) {
    let postsGridItem = item as! PostsGridCollectionViewItem

    self.thumbnailsQueue.async {
      guard let post = postsGridItem.file else {
        return
      }

      var image: NSImage
      do {
        image = try self.loadThumbnail(forPost: post)
      } catch {
        self.fetchLog.error("failed to load thumbnail image for post (globalID: \(post.globalID, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
        guard let fallbackThumbnailImage = NSImage(data: self.loadFallbackThumbnailData()) else {
          fatalError("failed to create image from fallback thumbnail data (?)")
        }
        image = fallbackThumbnailImage
      }

      DispatchQueue.main.async {
        postsGridItem.selectableImageView.image = image
      }
    }
  }
}

extension PostsViewController: NSCollectionViewDataSource {
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int)
    -> Int
  {
    return self.listing?.count ?? 0
  }

  func collectionView(
    _ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath
  ) -> NSCollectionViewItem {
    let item =
      self.collectionView.makeItem(
        withIdentifier: .postsGridItem,
        for: indexPath
      ) as! PostsGridCollectionViewItem

    let file = self.listing!.posts[indexPath.item]
    item.selectableImageView.contentsGravity = self.imageLayerGravity()
    item.file = file

    return item
  }
}
