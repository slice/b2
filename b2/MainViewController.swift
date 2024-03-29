import Cocoa
import Combine
import Path

let sortBottom = String(repeating: "z", count: 10)

class MainViewController: NSSplitViewController {
  @IBOutlet var tagsSplitItem: NSSplitViewItem!
  var tagsViewController: TagsViewController! {
    self.tagsSplitItem.viewController as? TagsViewController
  }

  @IBOutlet var postsSplitItem: NSSplitViewItem!
  var postsViewController: PostsViewController! {
    self.postsSplitItem.viewController as? PostsViewController
  }

  @IBOutlet var previewSplitItem: NSSplitViewItem!
  var previewViewController: PreviewViewController! {
    self.previewSplitItem.viewController as? PreviewViewController
  }

  private var infiniteScrollSubscriber: AnyCancellable!
  private var isLoadingMorePosts: Bool = false

  private var windowController: MainWindowController! {
    self.view.window?.windowController as? MainWindowController
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.postsViewController.onPostSelected = { [weak self] file in
      let tags = file.tags.sorted(by: { first, second in
        let firstN = first.namespace ?? sortBottom
        let secondN = second.namespace ?? sortBottom
        return (firstN, first.subtag) < (secondN, second.subtag)
      })

      self?.tagsViewController.tags = tags
      self?.tagsViewController.tableView.reloadData()

      if !(self?.previewSplitItem.isCollapsed ?? true) {
        self?.previewViewController.loadPreviewImage(at: file.imageURL)
      }
    }

    self.infiniteScrollSubscriber = self.postsViewController.scrolledNearEnd
      .throttle(for: .seconds(3), scheduler: DispatchQueue.main, latest: true)
      .flatMap { _ -> AnyPublisher<Void, Never> in
        guard self.booru.supportsPagination else {
          NSLog("halting infinite scroll subscriber; pagination is not supported for this booru")
          return Empty().eraseToAnyPublisher()
        }

        guard !(self.postsViewController.listing?.isExhausted ?? true) else {
          NSLog("halting infinite scroll subscriber; listing is already exhausted")
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
        self.postsViewController.applySnapshotWithLatestChunk()
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
    let listing = files.isEmpty ? nil : BooruListing(files: files, fromBooru: self.booru)
    self.postsViewController.listing = listing
    self.postsViewController.collectionView.deselectAll(nil)
    self.applySnapshot(ofListing: listing)
  }

  private func applySnapshot(ofListing listing: BooruListing?) {
    guard let collectionView = self.postsViewController.collectionView else {
      return
    }

    guard let dataSource = collectionView.dataSource as? NSCollectionViewDiffableDataSource<PostsGridSection, String> else {
      return
    }

    var snapshot = NSDiffableDataSourceSnapshot<PostsGridSection, String>()

    guard let listing = listing else {
      // Apply the empty snapshot.
      dataSource.apply(snapshot)
      return
    }

    snapshot.appendSections([.main])
    snapshot.appendItems(listing.posts.map(\.globalID), toSection: .main)

    dataSource.apply(snapshot)
  }
}
