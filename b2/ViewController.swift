import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    var hashes: [String] = []

    var database: MediaDatabase {
        let controller = self.view.window!.windowController as! WindowController
        return controller.database
    }

    override func viewDidAppear() {
        NSLog("Database from ViewController: \(database)")

        do {
            hashes = try self.database.media()
            NSLog("Fetched \(hashes.count) files")
        } catch let error {
            fatalError("Failed to fetch files: \(error)")
        }

        self.collectionView.reloadData()
    }
}

extension ViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.hashes.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = self.collectionView.makeItem(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MediaCollectionViewItem"),
            for: indexPath
        )

        let hash = self.hashes[indexPath.item]
        // TODO: Handle other file types
        let path = self.database.pathToHash(hash).string + ".png"
        item.imageView!.image = NSImage(byReferencingFile: path)

        return item
    }
}
