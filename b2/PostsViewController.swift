//
//  PostsViewController.swift
//  b2
//
//  Created by slice on 6/6/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa

class PostsViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    /// An array of files to display.
    var files: [BooruFile] = []

    var onFileSelected: ((BooruFile) -> Void)?

    private var defaultsObserver: NSObjectProtocol?

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

        // Don't draw a background color.
        self.collectionView.backgroundColors = [.clear]

        self.updateCollectionViewLayout()

        self.defaultsObserver = NotificationCenter.default.addObserver(forName: .preferencesChanged, object: nil, queue: nil) { [weak self] notification in
            self?.updateCollectionViewLayout()
        }
    }

    deinit {
        if let observer = self.defaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension PostsViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let lastIndexPath = indexPaths.max()!
        let item = collectionView.item(at: lastIndexPath) as? MediaCollectionViewItem

        if let file = item?.file {
            self.onFileSelected?(file)
        }
    }

    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        let mediaItem = item as! MediaCollectionViewItem

        // Only load thumbnails as the user scrolls.
        //
        // TODO: Don't call this when the image has already been loaded.
        //       I don't know how to easily determine this because
        //       `MediaCollectionViewItem`s can be reused by AppKit, and can
        //       result in incorrect images displaying when they're reused
        //       (e.g. when performing a search).
        //
        //       Newly created cells will have the proper `file` property, but
        //       will only ever get loaded once if we simply check if
        //       `mediaItem.imageView.image` is `nil`.
        //
        // TODO: Don't crash if we can't load the image, because it might fetch
        //       from the network.
        self.thumbnailsQueue.async {
            measure("Loading thumbnail for \(mediaItem.file.id)") {
                let data = try! Data(contentsOf: mediaItem.file.thumbnailImageURL)

                DispatchQueue.main.async {
                    mediaItem.imageView!.image = NSImage(data: data)!
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
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MediaCollectionViewItem"),
            for: indexPath
        ) as! MediaCollectionViewItem

        let file = self.files[indexPath.item]
        item.file = file
        item.imageView!.image = nil

        return item
    }
}
