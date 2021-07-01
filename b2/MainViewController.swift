import Cocoa
import Combine
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

  private var infiniteScrollSubscriber: AnyCancellable!
  private var isLoadingMorePosts: Bool = false

  private var windowController: MainWindowController! {
    self.view.window?.windowController as? MainWindowController
  }

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

    self.infiniteScrollSubscriber = self.postsViewController.scrolledNearEnd
      .throttle(for: .seconds(3), scheduler: DispatchQueue.main, latest: true)
      .flatMap { _ -> AnyPublisher<Void, Never> in
        guard self.booru.supportsPagination else {
          NSLog("halting infinite scroll subscriber; pagination is not supported for this booru")
          return Empty().eraseToAnyPublisher()
        }

        return Just(()).eraseToAnyPublisher()
      }
      .flatMap { self.postsViewController.listing.publisher }
      .flatMap {
        $0.loadMorePosts(withTags: self.windowController.query)
          .catch { error -> Empty<[BooruPost], Never> in
            self.presentError(error)
            return Empty()
          }
      }
      .receive(on: DispatchQueue.main)
      .sink { _ in
        self.postsViewController.collectionView.reloadData()
        self.windowController.updateFileCountSubtitle()
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
