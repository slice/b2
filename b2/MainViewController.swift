import Cocoa
import Path

let sortBottom = String(repeating: "z", count: 10)

class MainViewController: NSSplitViewController {
    @IBOutlet weak var tagsSplitItem: NSSplitViewItem!
    var tagsViewController: TagsViewController! {
        return self.tagsSplitItem.viewController as? TagsViewController
    }

    @IBOutlet weak var postsSplitItem: NSSplitViewItem!
    var postsViewController: PostsViewController! {
        return self.postsSplitItem.viewController as? PostsViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.postsViewController.onFileSelected = { [weak self] file in
            let tags = file.tags.sorted(by: { (first, second) in
                let firstN = first.namespace ?? sortBottom
                let secondN = second.namespace ?? sortBottom
                return (firstN, first.subtag) < (secondN, second.subtag)
            })

            self?.tagsViewController.tags = tags
            self?.tagsViewController.tableView.reloadData()
        }
    }

    /// The `Booru` to load and search from.
    var booru: Booru = NoneBooru() {
        didSet {
            // Reset the displayed tags.
            self.tagsViewController.tags = []
            self.tagsViewController.tableView.reloadData()
        }
    }

    /// The `BooruFile`s being viewed in the post grid.
    var files: [BooruFile] = [] {
        didSet {
            self.postsViewController.files = self.files
            // Reset the currently selected file and reload the collection view.
            self.resetPostsViewController()
        }
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

    private func resetPostsViewController() {
        self.postsViewController.collectionView.deselectAll(nil)
        self.postsViewController.collectionView.reloadData()
    }
}
