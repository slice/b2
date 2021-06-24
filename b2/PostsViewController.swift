//
//  PostsViewController.swift
//  b2
//
//  Created by slice on 6/6/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa
import os.log

extension NSUserInterfaceItemIdentifier {
    static let postsGridItem = Self(rawValue: "PostsGridCollectionViewItem")
}

class PostsViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    /// The listing that this controller is displaying.
    public var listing: BooruListing?

    /// A closure to be called when a new file is selected.
    public var onFileSelected: ((BooruFile) -> Void)?

    /// A closure to be called when scrolling nearly reaches the end of the
    /// listing.
    public var onScrolledNearEnd: (() -> Void)?

    private var defaultsObserver: NSObjectProtocol?
    private var scrollViewMagnifyEndObserver: NSObjectProtocol?
    private var clipViewBoundsChangedObserver: NSObjectProtocol?

    private let postsLog = Logger(subsystem: loggingSubsystem, category: "posts")
    private let fetchLog = Logger(subsystem: loggingSubsystem, category: "fetch")

    /// A `DispatchQueue` used for loading thumbnails.
    private let thumbnailsQueue = DispatchQueue(label: "thumbnails", attributes: .concurrent)

    private func imageLayerGravity() -> CALayerContentsGravity {
        guard let mode = PostsGridScalingMode(rawValue: Preferences.shared.get(.imageGridScalingMode)) else {
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

            self.scrollViewMagnifyEndObserver = NotificationCenter.default.addObserver(forName: NSScrollView.didEndLiveMagnifyNotification, object: scrollView, queue: nil) { [weak self] _ in
                let currentSize: Int = Preferences.shared.get(.imageGridThumbnailSize)
                let newSize = Int(Float(currentSize) * Float(scrollView.magnification))
                self?.postsLog.info("setting image grid thumbnail size to \(newSize) after magnifying to \(scrollView.magnification) (from \(currentSize))")
                Preferences.shared.set(.imageGridThumbnailSize, to: newSize)
                scrollView.magnification = 1
            }
        }

        self.updateCollectionViewLayout()

        self.defaultsObserver = NotificationCenter.default.addObserver(forName: .preferencesChanged, object: nil, queue: nil) { [weak self] _ in
            self?.updateCollectionViewLayout()
        }

        let clipView = scrollView.contentView
        clipView.postsBoundsChangedNotifications = true
        self.clipViewBoundsChangedObserver = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: clipView, queue: nil) { notification in
            self.loadMoreIfNearEnd(scrollView: scrollView)
        }

        self.collectionView.register(PostsGridCollectionViewItem.self, forItemWithIdentifier: .postsGridItem)
    }

    private func loadMoreIfNearEnd(scrollView: NSScrollView) {
        let clipView = scrollView.contentView
        let documentView = scrollView.documentView!
//        guard documentView.frame.height > clipView.bounds.height else {
//            self.postsLog.info("not triggering a fetch due to a bounds change because the grid content doesn't fit within the frame")
//            return
//        }
        let percentageScrolled = clipView.bounds.origin.y / (documentView.frame.height - clipView.bounds.height)
        if percentageScrolled >= 0.9 {
            self.postsLog.info("reached scrolling threshold")
            self.onScrolledNearEnd?()
        }
    }

    deinit {
        self.postsLog.notice("PostsViewController deinit")

        if let observer = self.defaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = self.scrollViewMagnifyEndObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = self.clipViewBoundsChangedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension PostsViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let lastIndexPath = indexPaths.max()!
        let item = collectionView.item(at: lastIndexPath) as? PostsGridCollectionViewItem

        if let file = item?.file {
            self.onFileSelected?(file)
        }
    }

    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        let postsGridItem = item as! PostsGridCollectionViewItem
        let cache = ImageCache.shared

        // Only load thumbnails as the user scrolls.
        //
        // TODO: Don't crash if we can't load the image, because it might fetch
        //       from the network.
        self.thumbnailsQueue.async {
            guard let file = postsGridItem.file else {
                return
            }

            if let image = cache.image(forID: file.id) {
                self.fetchLog.debug("using cached thumbnail for \(file.id)")

                DispatchQueue.main.async {
                    postsGridItem.selectableImageView.image = image
                }
            } else {
                self.fetchLog.info("fetching thumbnail for \(file.id)")

                guard let data = try? Data(contentsOf: file.thumbnailImageURL) else {
                    // TODO: Don't die, this code path is not fatal.
                    fatalError("failed to fetch image")
                }

                guard let image = NSImage(data: data) else {
                    // TODO: Don't die.
                    fatalError("failed to read image from fetched data")
                }

                cache.insert(image, forID: file.id)

                DispatchQueue.main.async {
                    postsGridItem.selectableImageView.image = image
                }
            }
        }
    }
}

extension PostsViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.listing?.count ?? 0
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = self.collectionView.makeItem(
            withIdentifier: .postsGridItem,
            for: indexPath
        ) as! PostsGridCollectionViewItem

        let file = self.listing!.posts[indexPath.item]
        item.selectableImageView.contentsGravity = self.imageLayerGravity()
        item.file = file

        return item
    }
}
