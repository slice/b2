import Cocoa
import Path_swift

class MainViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var statusBarLabel: NSTextField!
    @IBOutlet weak var booruSelectorButton: NSPopUpButton!

    /// A `DispatchQueue` used for fetching data from the database.
    let fetchQueue = DispatchQueue(label: "database", attributes: .concurrent)

    /// The current `Booru` being used.
    var booru: Booru!

    /// An array of currently loaded files.
    var files: [BooruFile] = [] {
        didSet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let formatted = formatter.string(from: NSNumber(value: self.files.count)) ?? String(self.files.count)
            let s = self.files.count == 1 ? "" : "s"

            self.statusBarLabel.stringValue = "\(formatted) file\(s)"
        }
    }

    /// The currently selected file.
    var selectedFile: BooruFile? {
        didSet {
            self.tableView.reloadData()
        }
    }

    /// Returns the selected file's tags, sorted for display.
    var selectedFileTags: [BooruTag] {
        guard let file = self.selectedFile else {
            return []
        }

        return file.tags.sorted(by: { (first, second) in
            let firstN = first.namespace ?? "zzz"
            let secondN = second.namespace ?? "zzz"
            return (firstN, first.subtag) < (secondN, second.subtag)
        })
    }
}

// MARK: - Booru

extension MainViewController {
    enum BooruType: Int {
        case none = -1
        case hydrusNetwork
        case e621
        case e926
    }

    /// Asynchronously performs a search for files with tags and displays them
    /// in the collection view.
    func searchAsync(tags: [String]) {
        self.selectedFile = nil
        self.statusBarLabel.stringValue = "Searching..."

        self.fetchQueue.async {
            let files = try! measure("Query for \(tags)") {
                return try self.booru.search(forFilesWithTags: tags)
            }

            NSLog("Query returned \(files.count) file(s).")

            DispatchQueue.main.async {
                self.files = files
                self.collectionView.reloadData()
            }
        }
    }

    /// Asynchronously fetches the initial files and displays them in the
    /// collection view.
    func loadInitialFiles() {
        self.statusBarLabel.stringValue = "Loading files..."

        self.fetchQueue.async {
            let files = try! measure("Fetching all files") {
                return try self.booru.initialFiles()
            }

            NSLog("Fetched \(files.count) file(s)")

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

    /// Loads the Hydrus database.
    func loadHydrusDatabase() {
        let path = Path.home / "Library" / "Hydrus"

        guard path.isDirectory else {
            self.showDatabaseLoadFailureMessage("No database found at \(path.string)")
            return
        }

        do {
            try measure("Loading database") {
                self.booru = try HydrusDatabase(databasePath: path)
            }
        } catch let error {
            self.showDatabaseLoadFailureMessage(error.localizedDescription)
        }
    }

    /// Loads the currently selected booru.
    func loadCurrentlySelectedBooru() {
        let booru = BooruType(rawValue: self.booruSelectorButton.selectedItem!.tag)!
        NSLog("Loading booru: \"\(booru)\"")
        self.loadBooru(booru)
    }

    /// Loads a booru.
    func loadBooru(_ booru: BooruType) {
        // Reset some state.
        self.files = []
        self.collectionView.reloadData()
        self.selectedFile = nil

        switch booru {
        case .none:
            self.booru = NoneBooru()
        case .hydrusNetwork:
            self.loadHydrusDatabase()
        case .e621:
            NSLog("TODO")
        case .e926:
            NSLog("TODO")
        }
    }
}

// MARK: - View Controller

extension MainViewController {
    @IBAction func changeBooru(_ sender: NSPopUpButton) {
        self.loadCurrentlySelectedBooru()
        self.loadInitialFiles()
    }

    override func viewDidLoad() {
        let layout = self.collectionView.collectionViewLayout! as! NSCollectionViewGridLayout
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
    }

    override func viewDidAppear() {
        self.loadCurrentlySelectedBooru()

        NSLog("Performing first initial files load")
        self.loadInitialFiles()
    }
}

// MARK: - Table View

extension MainViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.selectedFileTags.count
    }
}

extension MainViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TagCell"), owner: nil) as! NSTableCellView
        let tag = self.selectedFileTags[row]
        cell.textField!.stringValue = tag.description
        return cell
    }
}

// MARK: - Collection View

extension MainViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        if collectionView.selectionIndexes.isEmpty {
            self.selectedFile = nil
        }
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let lastIndexPath = indexPaths.max()!
        let item = collectionView.item(at: lastIndexPath) as? MediaCollectionViewItem
        self.selectedFile = item?.file
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
        mediaItem.loadThumbnail()
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
