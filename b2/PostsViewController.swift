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

    /// An array of files to display.
    var files: [BooruFile] = []

    var onFileSelected: ((BooruFile) -> Void)?

    private var defaultsObserver: NSObjectProtocol?
    private var scrollViewMagnifyEndObserver: NSObjectProtocol?

    private let postsLog = Logger(subsystem: loggingSubsystem, category: "posts")
    private let fetchLog = Logger(subsystem: loggingSubsystem, category: "fetch")

    /// A cache for thumbnail image data.
    private var thumbnailCache: NSCache<NSNumber, NSImage> = NSCache()

    /// A `DispatchQueue` used for loading thumbnails.
    private let thumbnailsQueue = DispatchQueue(label: "thumbnails", attributes: .concurrent)

    private func updateCollectionViewLayout() {
        let spacing: Int = Preferences.shared.get(.imageGridSpacing)
        let size: Int = Preferences.shared.get(.imageGridThumbnailSize)

        let layout = self.collectionView.collectionViewLayout! as! NSCollectionViewGridLayout
        layout.minimumInteritemSpacing = CGFloat(spacing)
        layout.minimumLineSpacing = CGFloat(spacing)
        layout.minimumItemSize = NSSize(width: size, height: size)
        layout.maximumItemSize = NSSize(width: size, height: size)
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

        self.collectionView.register(PostsGridCollectionViewItem.self, forItemWithIdentifier: .postsGridItem)
    }

    deinit {
        self.postsLog.notice("PostsViewController deinit")

        if let observer = self.defaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = self.scrollViewMagnifyEndObserver {
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

        // Only load thumbnails as the user scrolls.
        //
        // TODO: Don't crash if we can't load the image, because it might fetch
        //       from the network.
        self.thumbnailsQueue.async {
            guard let file = postsGridItem.file else {
                return
            }

            let key = NSNumber(value: file.id)

            if let image = self.thumbnailCache.object(forKey: key) {
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

                self.thumbnailCache.setObject(image, forKey: key)

                DispatchQueue.main.async {
                    postsGridItem.selectableImageView.image = image
                }
            }
        }
    }
}

extension PostsViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.files.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = self.collectionView.makeItem(
            withIdentifier: .postsGridItem,
            for: indexPath
        ) as! PostsGridCollectionViewItem

        let file = self.files[indexPath.item]
        item.file = file

        return item
    }
}
