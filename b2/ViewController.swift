import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    var files: [MediaFile] = []

    var database: MediaDatabase {
        let controller = self.view.window!.windowController as! WindowController
        return controller.database
    }

    override func viewDidAppear() {
        NSLog("Database from ViewController: \(database)")

        do {
            self.files = try self.database.media()
            NSLog("Fetched \(self.files.count) files")
        } catch let error {
            fatalError("Failed to fetch files: \(error)")
        }

        self.collectionView.reloadData()
    }
}

extension ViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.files.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = self.collectionView.makeItem(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MediaCollectionViewItem"),
            for: indexPath
        )

        let file = self.files[indexPath.item]
        item.imageView!.image = NSImage(byReferencingFile: file.path)

        return item
    }
}
