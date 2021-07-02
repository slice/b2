import Cocoa

class TagsViewController: NSViewController {
  @IBOutlet var tableView: NSTableView!
  var tags: [BooruTag] = []

  private var defaultsObserver: NSObjectProtocol?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.updateSizing()

    self.defaultsObserver = NotificationCenter.default.addObserver(
      forName: .preferencesChanged, object: nil, queue: nil
    ) { [weak self] _ in
      self?.updateSizing()
    }
  }

  private func updateSizing() {
    let compactTagsEnabled: Bool = Preferences.shared.get(.compactTagsEnabled)
    // Refer to macOS HIG.
    // TODO: Maybe don't hardcode these. Use row styles?
    self.tableView.rowHeight = compactTagsEnabled ? 17 : 24
  }

  deinit {
    if let observer = self.defaultsObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }
}

extension TagsViewController: NSTableViewDataSource {
  func numberOfRows(in _: NSTableView) -> Int {
    self.tags.count
  }
}

extension TagsViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
    let cell =
      tableView.makeView(
        withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TagCell"), owner: nil
      )
      as! NSTableCellView
    let tag = self.tags[row]
    cell.textField!.stringValue = tag.description
    return cell
  }
}
