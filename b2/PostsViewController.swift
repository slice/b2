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

    /// An array of files to display.
    var files: [BooruFile] = []

    var onFileSelected: ((BooruFile) -> Void)?

    /// A `DispatchQueue` used for loading thumbnails.
    private let thumbnailsQueue = DispatchQueue(label: "thumbnails", attributes: .concurrent)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Reduce the spacing between items.
        let layout = self.collectionView.collectionViewLayout! as! NSCollectionViewGridLayout
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0

        // Don't draw a background color.
        self.collectionView.backgroundColors = [.clear]
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
