import Cocoa
import Path_swift

class ViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var tableView: NSTableView!

    let fetchQueue = DispatchQueue(label: "database", attributes: .concurrent)
    var database: HydrusDatabase!
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

    /// Fetch all `HydrusFile`s in the database.
    func fetchAllFiles() throws -> [HydrusFile] {
        let files = try self.database.database.read { db in
            return try self.database.masterDatabase.read { masterDb in
                return try self.database.fetchAllFiles(mainDatabase: db, masterDatabase: masterDb)
            }
        }

        return files
    }

    /// Perform a search for files with all specified tags.
    func performSearch(tags: [String]) throws {
        self.currentlySelectedFile = nil

        self.files = try measure("Query for \(tags)") {
            return try self.database.search(tags: tags)
        }

        NSLog("Query returned \(self.files.count) file(s).")

        self.collectionView.reloadData()
    }

    /// Loads the database in ~/Library/Hydrus.
    func loadDatabase() {
        do {
            let path = Path.home / "Library" / "Hydrus"
            self.database = try HydrusDatabase(databasePath: path)
        } catch let error {
            let alert = NSAlert()
            alert.messageText = "Failed to load database"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.beginSheetModal(for: self.view.window!, completionHandler: { _ in
                self.view.window!.close()
            })
        }
    }

    /// Fetches all files and loads them into the collection view, asynchronously.
    func loadAllFilesAsync() {
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

extension ViewController {
    override func viewDidLoad() {
        let layout = self.collectionView.collectionViewLayout! as! NSCollectionViewGridLayout
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
    }

    override func viewDidAppear() {
        measure("Loading database") {
            self.loadDatabase()
        }
        NSLog("Database: \(self.database!)")

        NSLog("Loading all files")
        self.loadAllFilesAsync()
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
