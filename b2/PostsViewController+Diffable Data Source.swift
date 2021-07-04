import Cocoa

enum PostsGridSection: CaseIterable {
  case main
}

extension PostsViewController {
  func makeDiffableDataSource() -> NSCollectionViewDiffableDataSource<PostsGridSection, String> {
    NSCollectionViewDiffableDataSource(collectionView: self.collectionView) {
      (collectionView: NSCollectionView, indexPath: IndexPath, itemIdentifier: String) -> NSCollectionViewItem? in
      let item = collectionView.makeItem(withIdentifier: .postsGridItem, for: indexPath) as! PostsGridCollectionViewItem
      // XXX: This is probably too slow. Profile this and optimize it if necessary.
      let post = self.listing?.posts.first(where: { $0.globalID == itemIdentifier })
      item.post = post
      return item
    }
  }

  /// Update the current snapshot with the latest chunk from the current listing.
  func applySnapshotWithLatestChunk() {
    var snapshot = self.dataSource.snapshot()
    guard let listing = listing else {
      NSLog("tried to update snapshot with latest chunk when there's no listing")
      return
    }
    guard let latestChunk = listing.chunks.last else {
      NSLog("tried to update snapshot without a latest chunk")
      return
    }
    snapshot.appendItems(latestChunk.map(\.globalID))
    self.dataSource.apply(snapshot, animatingDifferences: true)
  }
}
