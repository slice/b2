import Carbon.HIToolbox.Events
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
  @IBOutlet weak var searchField: NSSearchField!

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
    let filePath =
      UserDefaults.standard.string(forKey: "hydrusDatabaseBasePath")
      ?? "/Volumes/launchpad/media/hydrus2"
    let fileURL = URL(fileURLWithPath: filePath)
    let path = Path(url: fileURL)!

    guard path.isDirectory else {
      self.presentError(CocoaError.error(.fileReadNoSuchFile, userInfo: nil, url: fileURL))
      return
    }

    do {
      try measure("Loading database") {
        self.viewController.booru = try HydrusDatabase(atBasePath: path)
      }
    } catch {
      self.presentError(CocoaError.error(.fileReadCorruptFile, userInfo: nil, url: fileURL))
    }
  }

  /// Loads a booru.
  func loadBooru(ofType booru: BooruType) {
    // Reset some state.
    self.viewController.setInitialListing(fromFiles: [])

    switch booru {
    case .none:
      self.viewController.booru = NoneBooru()
    case .hydrusNetwork:
      self.loadHydrusDatabase()
    case .e621:
      self.viewController.booru = OuroborosBooru(
        named: "e621", baseUrl: URL(string: "https://e621.net")!)
    case .e926:
      self.viewController.booru = OuroborosBooru(
        named: "e926", baseUrl: URL(string: "https://e926.net")!)
    }
  }

  var query: [String] {
    self.searchField.stringValue.split(separator: " ").map { String($0) }
  }

  private var allowNextMouseTriggeredSearch = false

  @IBAction func performSearch(_ sender: NSSearchField) {
    if let currentEvent = NSApp.currentEvent {
      if currentEvent.type == .keyDown && currentEvent.keyCode == kVK_Delete {
        // For some reason, the action is dispatched if the user empties the
        // search field while a "searching session" is not active. Ignore this.
        return
      }

      if currentEvent.type == .leftMouseUp {
        // A search was triggered from pressing the clear button! But the
        // action is dispatched twice for some reason. Allow the next one to
        // pass through.
        if !self.allowNextMouseTriggeredSearch {
          self.allowNextMouseTriggeredSearch = true
          return
        }

        self.allowNextMouseTriggeredSearch = false
      }
    }

    // Clear the views.
    self.viewController.setInitialListing(fromFiles: [])
    self.viewController.tagsViewController.tags = []
    self.viewController.tagsViewController.tableView.reloadData()

    let tags = self.query

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

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(createdTabWillClose),
      name: NSWindow.willCloseNotification,
      object: controller.window
    )
  }

  @objc private func createdTabWillClose(notification: Notification) {
    self.createdTab = nil
  }

  func updateFileCountSubtitle() {
    let fileCount = self.viewController.postsViewController.listing?.count ?? 0

    if fileCount == 0 {
      self.window?.subtitle = ""
      return
    }

    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    let formatted = formatter.string(from: NSNumber(value: fileCount)) ?? String(fileCount)
    let s = fileCount == 1 ? "" : "s"

    self.window?.subtitle = "\(formatted) post\(s)"
  }

  private func handleQueryResult(_ result: Result<[BooruPost], Error>) {
    DispatchQueue.main.async {
      self.viewController.postsViewController.progressIndicator.stopAnimation(nil)
    }

    switch result {
    case .success(let files):
      NSLog("query returned \(files.count) file(s)")
      DispatchQueue.main.async {
        self.viewController.setInitialListing(fromFiles: files)
      }
    case .failure(let error):
      NSLog("failed to query: \(error)")
      DispatchQueue.main.async {
        self.presentError(B2Error.searchFailure(error))
      }
    }

    DispatchQueue.main.async {
      self.updateFileCountSubtitle()
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

  deinit {
    NSLog("MainWindowController deinit")
  }
}
