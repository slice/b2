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
            self.postsViewController.listing = self.files.isEmpty ? nil : BooruListing(files: self.files, fromBooru: self.booru)
            self.reloadPostsGrid()
        }
    }

    private func reloadPostsGrid() {
        self.postsViewController.collectionView.deselectAll(nil)
        self.postsViewController.collectionView.reloadData()
    }
}
