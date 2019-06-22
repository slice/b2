import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var tableView: NSTableView!

    var files: [HydrusFile] = []
    var currentlySelectedFileTags: [HydrusTag]?
    var currentlySelectedFile: HydrusFile? {
        didSet {
            guard let file = self.currentlySelectedFile else {
                self.currentlySelectedFileTags = []
                self.tableView.reloadData()
                return
            }

            measure("Fetching tags for \(file.hashId)") {
                let tags = try! file.tags()

                let sorted = tags.sorted(by: { (first, second) in
                    let firstNamespace = first.namespace.isDefault ? "zzzz" : first.namespace.text
                    let secondNamespace = second.namespace.isDefault ? "zzzz" : second.namespace.text
                    return (firstNamespace, first.subtag.text) < (secondNamespace, second.subtag.text)
                })

                self.currentlySelectedFileTags = sorted
            }

            self.tableView.reloadData()
        }
    }

    var database: HydrusDatabase {
        let controller = self.view.window!.windowController as! WindowController
        return controller.database
    }

    func loadAllMedia() throws {
        try self.database.database.read { db in
            try self.database.masterDatabase.read { masterDb in
                self.files = try measure("Fetching all database files") {
                    return try self.database.fetchAllLocalMedia(mainDatabase: db, masterDatabase: masterDb)
                }
            }
        }

        NSLog("Fetched \(self.files.count) file(s)")
        self.collectionView.reloadData()
    }

    func performSearch(tags: [String]) throws {
        self.currentlySelectedFile = nil

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
