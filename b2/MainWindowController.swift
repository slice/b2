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
    var createdTab: MainWindowController?
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

    var booru: Booru = NoneBooru() {
        didSet {
            self.viewController.booru = self.booru
        }
    }

    var files: [BooruFile] = [] {
        didSet {
            self.viewController.files = self.files
        }
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
                self.booru = try HydrusDatabase(atBasePath: path)
            }
        } catch {
            self.presentError(B2Error.hydrusDatabaseFailedToLoad(error))
        }
    }

    /// Loads a booru.
    func loadBooru(ofType booru: BooruType) {
        // Reset some state.
        self.files = []

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

    @IBAction func performSearch(_ sender: NSSearchField) {
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
        switch result {
        case .success(let files):
            NSLog("query returned \(files.count) file(s)")
            DispatchQueue.main.async {
                self.files = files
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
        self.files = []

        NSLog("querying: \(tags)")

        self.booru.search(forTags: tags) { result in
            self.handleQueryResult(result)
        }
    }

    /// Asynchronously fetches the initial files and displays them in the
    /// collection view.
    func loadInitialFiles() {
        self.booru.initialFiles { result in
            self.handleQueryResult(result)
        }
    }
}
