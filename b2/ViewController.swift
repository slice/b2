import Cocoa
import SQLite

class ViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var tableView: NSTableView!

    var files: [MediaFile] = []
    var currentlySelectedFileTags: [Tag]?
    var currentlySelectedFile: MediaFile? {
        didSet {
            measure("Fetching tags for \(self.currentlySelectedFile.hashId)") {
                guard let tags = try? self.currentlySelectedFile!.tags() else {
                    NSLog("Fetching tags failed")
                    return
                }

                let sorted = tags.sorted(by: { (first, second) in
                    let firstNamespace = first.namespace?.namespace ?? "zzzz"
                    let secondNamespace = second.namespace?.namespace ?? "zzzz"
                    return (firstNamespace, first.tag) < (secondNamespace, second.tag)
                })

                self.currentlySelectedFileTags = sorted
            }

            self.tableView.reloadData()
        }
    }

    var database: MediaDatabase {
        let controller = self.view.window!.windowController as! WindowController
        return controller.database
    }

    func loadAllMedia() throws {
        self.files = try measure("Fetching all database files") {
            return try self.database.media()
        }
        NSLog("Fetched \(self.files.count) file(s)")
        self.collectionView.reloadData()
    }

    func performSearch(tags: [String]) throws {
        self.files = try measure("Query for \(tags)") {
            return try self.database.search(tags: tags)
        }

        NSLog("Query returned \(self.files.count) file(s).")

        self.collectionView.reloadData()
    }
}

extension ViewController {
    override func viewDidLoad() {
        let layout = self.collectionView.collectionViewLayout! as! NSCollectionViewGridLayout
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
    }

    override func viewDidAppear() {
        NSLog("Database: \(database)")
        try! self.loadAllMedia()
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.currentlySelectedFileTags?.count ?? 0
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TagCell"), owner: nil) as! NSTableCellView
        let tag = self.currentlySelectedFileTags![row]
        cell.textField!.stringValue = tag.description
        cell.toolTip = String(tag.id)
        return cell
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
        ) as! MediaCollectionViewItem

        let file = self.files[indexPath.item]
        item.file = file

        return item
    }
}
