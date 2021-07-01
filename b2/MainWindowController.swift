import Carbon.HIToolbox.Events
import Cocoa
import Path
import os.log

enum BooruType: Int {
  case none = -1
  case hydrusNetwork
  case e621
  case e926
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

  private let log = Logger(subsystem: loggingSubsystem, category: "window")

  @IBAction func booruChanged(_ sender: Any) {
    let selectedBooruTag = self.booruPickerButton.selectedItem!.tag
    let type = BooruType(rawValue: selectedBooruTag)!
    do {
      try self.loadBooru(ofType: type)
      self.loadInitialFiles()
    } catch {
      self.presentError(error)
    }
  }

  /// Loads the Hydrus database.
  private func loadHydrusDatabase() throws {
    guard
      let hydrusHost =
        URL(
          string: UserDefaults.standard.string(forKey: "hydrusClientAPIBaseURL")
            ?? "http://localhost:45869")
    else {
      throw B2Error.error(code: .invalidBooruEndpoint)
    }

    guard let hydrusAccessKey = UserDefaults.standard.string(forKey: "hydrusClientAPIAccessKey")
    else {
      throw B2Error.error(code: .invalidBooruCredentials)
    }

    self.viewController.booru = ConstellationBooru(baseURL: hydrusHost, accessKey: hydrusAccessKey)
  }

  /// Loads a booru.
  func loadBooru(ofType booru: BooruType) throws {
    // Reset some state.
    self.viewController.setInitialListing(fromFiles: [])

    switch booru {
    case .none:
      self.viewController.booru = NoneBooru()
    case .hydrusNetwork:
      try self.loadHydrusDatabase()
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
        // action is dispatched twice for some reason. Ignore this dispatch and
        // allow the next one to pass through.
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
      self.log.info("query returned \(files.count) file(s)")
      DispatchQueue.main.async {
        self.viewController.setInitialListing(fromFiles: files)
      }
    case .failure(let error):
      let error = error as NSError
      self.log.error("failed to query: \(error, privacy: .public)")
      DispatchQueue.main.async {
        self.presentError(
          B2Error.error(code: .queryFailed, userInfo: [NSUnderlyingErrorKey: error]))
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
