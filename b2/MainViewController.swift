import Cocoa
import Path_swift

class MainViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var statusBarLabel: NSTextField!

    /// A `DispatchQueue` used for fetching data from the database.
    let fetchQueue = DispatchQueue(label: "database", attributes: .concurrent)

    /// The current `HydrusDatabase`.
    var database: HydrusDatabase!

    /// An array of currently loaded files.
    var files: [HydrusFile] = [] {
        didSet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let formatted = formatter.string(from: NSNumber(value: self.files.count)) ?? String(self.files.count)
            let s = self.files.count == 1 ? "" : "s"

            self.statusBarLabel.stringValue = "\(formatted) file\(s)"
        }
    }

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

    /// Fetch all `HydrusFile`s in the database.
    func fetchAllFiles() throws -> [HydrusFile] {
        let files = try self.database.database.read { db in
            return try self.database.masterDatabase.read { masterDb in
                return try self.database.fetchAllFiles(mainDatabase: db, masterDatabase: masterDb)
            }
        }

        return files
    }

    /// Asynchronously performs a search for files with tags and displays them
    /// in the collection view.
    func searchAsync(tags: [String]) {
        self.currentlySelectedFile = nil
        self.statusBarLabel.stringValue = "Searching..."

        self.fetchQueue.async {
            let files = try! measure("Query for \(tags)") {
                return try self.database.search(tags: tags)
            }

            NSLog("Query returned \(files.count) file(s).")

            DispatchQueue.main.async {
                self.files = files
                self.collectionView.reloadData()
            }
        }
    }

    func showDatabaseLoadFailureMessage(_ text: String) {
        let alert = NSAlert()
        alert.messageText = "Failed to load database"
        alert.informativeText = text
        alert.alertStyle = .critical
        alert.beginSheetModal(for: self.view.window!, completionHandler: { _ in
            self.view.window!.close()
        })
    }

    /// Loads the databases.
    func loadDatabases(at path: Path) {
        do {
            self.database = try HydrusDatabase(databasePath: path)
        } catch let error {
            self.showDatabaseLoadFailureMessage(error.localizedDescription)
        }
    }

    /// Fetches all files and loads them into the collection view, asynchronously.
    func loadAllFilesAsync() {
        self.statusBarLabel.stringValue = "Loading files..."

        self.fetchQueue.async {
            let files = try! measure("Fetching all files") {
                return try self.fetchAllFiles()
            }

            NSLog("Fetched \(files.count) file(s)")

            DispatchQueue.main.async {
                self.files = files
                self.collectionView.reloadData()
            }
        }
    }
}

extension MainViewController {
    override func viewDidLoad() {
        let layout = self.collectionView.collectionViewLayout! as! NSCollectionViewGridLayout
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
    }

    override func viewDidAppear() {
        let path = Path.home / "Library" / "Hydrus"

        guard path.isDirectory else {
            self.showDatabaseLoadFailureMessage("No database found at \(path.string)")
            return
        }

        measure("Loading database") {
            self.loadDatabases(at: path)
        }

        guard self.database != nil else {
            return
        }

        NSLog("Database: \(self.database!)")

        NSLog("Loading all files")
        self.loadAllFilesAsync()
    }
}

extension MainViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.currentlySelectedFileTags?.count ?? 0
    }
}

extension MainViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TagCell"), owner: nil) as! NSTableCellView
        let tag = self.currentlySelectedFileTags![row]
        cell.textField!.stringValue = tag.description
        cell.toolTip = String(tag.id)
        return cell
    }
}

extension MainViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        if collectionView.selectionIndexes.isEmpty {
            self.currentlySelectedFile = nil
        }
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let lastIndexPath = indexPaths.max()!
        let item = collectionView.item(at: lastIndexPath) as? MediaCollectionViewItem
        self.currentlySelectedFile = item?.file
    }
}

extension MainViewController: NSCollectionViewDataSource {
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
