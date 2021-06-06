import Cocoa
import Path

class MainViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var statusBarLabel: NSTextField!
    @IBOutlet weak var booruSelectorButton: NSPopUpButton!

    /// A `DispatchQueue` used for fetching data.
    let fetchQueue = DispatchQueue(label: "fetch", attributes: .concurrent)

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

    func errorSheet(title: String, description: String, closesWindow: Bool = false) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = description
        alert.alertStyle = .critical
        let completionHandler: ((NSApplication.ModalResponse) -> Void)? =
            closesWindow ? { _ in self.view.window!.close() } : nil
        alert.beginSheetModal(for: self.view.window!, completionHandler: completionHandler)
    }

    /// Asynchronously performs a search for files with tags and displays them
    /// in the collection view.
    func searchAsync(tags: [String]) {
        self.files = []
        self.collectionView.reloadData()
        self.selectedFile = nil
        self.statusBarLabel.stringValue = "Searching..."

        self.fetchQueue.async {
            var queriedFiles: [BooruFile]

            do {
                queriedFiles = try measure("Query for \(tags)") {
                    return try self.booru.search(forFilesWithTags: tags)
                }
            } catch {
                NSLog("Failed to query: \(error)")
                DispatchQueue.main.async {
                    self.errorSheet(
                        title: "Failed to search for files",
                        description: error.localizedDescription
                    )
                }
                return
            }

            NSLog("Query returned \(queriedFiles.count) file(s).")

            DispatchQueue.main.async {
                self.files = queriedFiles
                self.collectionView.reloadData()
            }
        }
    }

    /// Asynchronously fetches the initial files and displays them in the
    /// collection view.
    func loadInitialFiles() {
        self.statusBarLabel.stringValue = "Loading files..."

        self.fetchQueue.async {
            var fetchedFiles: [BooruFile]

            do {
                fetchedFiles = try measure("Fetching all files") {
                    return try self.booru.initialFiles()
                }
            } catch {
                NSLog("Failed to fetch initial files: \(error)")
                DispatchQueue.main.async {
                    self.errorSheet(
                        title: "Failed to fetch initial files",
                        description: error.localizedDescription
                    )
                }
                return
            }

            NSLog("Fetched \(fetchedFiles.count) file(s)")

            DispatchQueue.main.async {
                self.files = fetchedFiles
                self.collectionView.reloadData()
            }
        }
    }

    /// Loads the Hydrus database.
    func loadHydrusDatabase() {
        let path = Path.home / "Library" / "Hydrus"

        guard path.isDirectory else {
            self.errorSheet(
                title: "Failed to load database",
                description: "No database found at \(path.string)...",
                closesWindow: true
            )
            return
        }

        do {
            try measure("Loading database") {
                self.booru = try HydrusDatabase(databasePath: path)
            }
        } catch {
            NSLog("Failed to load database: \(error)")
            self.errorSheet(
                title: "Failed to load database",
                description: error.localizedDescription,
                closesWindow: true
            )
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
            self.booru = OuroborosBooru(baseUrl: URL(string: "https://e621.net")!)
        case .e926:
            self.booru = OuroborosBooru(baseUrl: URL(string: "https://e926.net")!)
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
        //
        // TODO: Don't crash if we can't load the image, because it might fetch
        //       from the network.
        self.fetchQueue.async {
            measure("Loading thumbnail for \(mediaItem.file.id)") {
                let data = try! Data(contentsOf: mediaItem.file.thumbnailImageURL)

                DispatchQueue.main.async {
                    mediaItem.imageView!.image = NSImage(data: data)!
                }
            }
        }
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
        item.imageView!.image = nil

        return item
    }
}
