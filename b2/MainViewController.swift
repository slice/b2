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

  private var isLoadingMorePosts: Bool = false

  override func viewDidLoad() {
    super.viewDidLoad()

    self.postsViewController.onPostSelected = { [weak self] file in
      let tags = file.tags.sorted(by: { (first, second) in
        let firstN = first.namespace ?? sortBottom
        let secondN = second.namespace ?? sortBottom
        return (firstN, first.subtag) < (secondN, second.subtag)
      })

      self?.tagsViewController.tags = tags
      self?.tagsViewController.tableView.reloadData()
    }

    self.postsViewController.onScrolledNearEnd = { [weak self] in
      guard let isAlreadyLoading = self?.isLoadingMorePosts, !isAlreadyLoading else {
        return
      }
      self?.isLoadingMorePosts = true
      guard let listing = self?.postsViewController.listing else { return }
      // TODO: can we like,, not,,, please,
      guard let windowController = self?.view.window?.windowController as? MainWindowController
      else { return }
      listing.loadMorePosts(withTags: windowController.query) { [weak self] result in
        switch result {
        case .failure(let error):
          NSLog("scrolling-triggered fetch failed to load more posts: \(error)")
          self?.presentError(error)
        case .success(let posts):
          NSLog("scrolling-triggered fetch resulted in \(posts.count) posts")

          DispatchQueue.main.async {
            self?.postsViewController.collectionView.reloadData()
            windowController.updateFileCountSubtitle()
          }
        }
      }

      // Delay further calls of this closure so we don't repeatedly fetch
      // more posts.
      let deadline = DispatchTime.now().advanced(by: .seconds(2))
      DispatchQueue.main.asyncAfter(deadline: deadline) {
        NSLog("isNotLoadingPostsAnymore")
        self?.isLoadingMorePosts = false
      }
    }
  }

  /// The `Booru` to load and search from.
  var booru: Booru = NoneBooru() {
    didSet {
      // Reset the displayed tags.
      self.tagsViewController.tags = []
      self.tagsViewController.tableView.reloadData()
      self.isLoadingMorePosts = false
    }
  }

  func setInitialListing(fromFiles files: [BooruPost]) {
    self.postsViewController.listing =
      files.isEmpty ? nil : BooruListing(files: files, fromBooru: self.booru)
    self.reloadPostsGrid()
  }

  private func reloadPostsGrid() {
    self.postsViewController.collectionView.deselectAll(nil)
    self.postsViewController.collectionView.reloadData()
  }
}
