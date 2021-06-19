import Cocoa
import Path

enum BooruType: Int {
    case none = -1
    case hydrusNetwork
    case e621
    case e926
}

enum B2Error: Error {
    case hydrusDatabaseNotFound
    case hydrusDatabaseFailedToLoad(Error)

    case searchFailure(Error)
    case initialLoadFailure(Error)
}

class MainWindowController: NSWindowController {
    private var createdTab: MainWindowController?
    @IBOutlet weak var booruPickerButton: NSPopUpButton!

    /// A `DispatchQueue` used for fetching data.
    private let fetchQueue = DispatchQueue(label: "fetch", attributes: .concurrent)

    private var viewController: MainViewController {
        return self.contentViewController as! MainViewController
    }

    @IBAction func booruChanged(_ sender: Any) {
        let selectedBooruTag = self.booruPickerButton.selectedItem!.tag
        let type = BooruType(rawValue: selectedBooruTag)!
        self.loadBooru(ofType: type)
        self.loadInitialFiles()
    }

    /// Loads the Hydrus database.
    private func loadHydrusDatabase() {
        // oh yeah, we're hardcoding this
        let path = Path(url: URL(string: "file:///Volumes/launchpad/media/hydrus2")!)!

        guard path.isDirectory else {
            self.presentError(B2Error.hydrusDatabaseNotFound)
            return
        }

        do {
            try measure("Loading database") {
                self.viewController.booru = try HydrusDatabase(atBasePath: path)
            }
        } catch {
            self.presentError(B2Error.hydrusDatabaseFailedToLoad(error))
        }
    }

    /// Loads a booru.
    func loadBooru(ofType booru: BooruType) {
        // Reset some state.
        self.viewController.files = []

        switch booru {
        case .none:
            self.viewController.booru = NoneBooru()
        case .hydrusNetwork:
            self.loadHydrusDatabase()
        case .e621:
            self.viewController.booru = OuroborosBooru(baseUrl: URL(string: "https://e621.net")!)
        case .e926:
            self.viewController.booru = OuroborosBooru(baseUrl: URL(string: "https://e926.net")!)
        }
    }

    @IBAction func performSearch(_ sender: NSSearchField) {
        // Clear the views.
        self.viewController.files = []
        self.viewController.tagsViewController.tags = []
        self.viewController.tagsViewController.tableView.reloadData()

        let tags = sender.stringValue.split(separator: " ").map { String($0) }

        if tags.isEmpty {
            self.loadInitialFiles()
        } else {
            self.searchAsynchronously(withTags: tags)
        }
    }

    override func newWindowForTab(_ sender: Any?) {
        let controller = self.storyboard!.instantiateInitialController() as! MainWindowController
        self.window!.addTabbedWindow(controller.window!, ordered: .above)
        controller.window!.makeKeyAndOrderFront(self)
        self.createdTab = controller
    }

    private func handleQueryResult(_ result: Result<[BooruFile], Error>) {
        DispatchQueue.main.async {
            self.viewController.postsViewController.progressIndicator.stopAnimation(nil)
        }

        switch result {
        case .success(let files):
            NSLog("query returned \(files.count) file(s)")
            DispatchQueue.main.async {
                self.viewController.files = files
            }
        case .failure(let error):
            NSLog("failed to query: \(error)")
            DispatchQueue.main.async {
                self.presentError(B2Error.searchFailure(error))
            }
        }
    }

    /// Asynchronously performs a search for files with tags and displays them
    /// in the collection view.
    func searchAsynchronously(withTags tags: [String]) {
        self.viewController.postsViewController.progressIndicator.startAnimation(nil)
        NSLog("querying: \(tags)")

        self.viewController.booru.search(forTags: tags) { result in
            self.handleQueryResult(result)
        }
    }

    /// Asynchronously fetches the initial files and displays them in the
    /// collection view.
    func loadInitialFiles() {
        self.viewController.postsViewController.progressIndicator.startAnimation(nil)

        self.viewController.booru.initialFiles { result in
            self.handleQueryResult(result)
        }
    }
}
