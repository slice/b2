import Cocoa

enum PostsGridSection: CaseIterable {
  case main
}

extension PostsViewController {
  func makeDiffableDataSource() -> NSCollectionViewDiffableDataSource<PostsGridSection, String> {
    NSCollectionViewDiffableDataSource(collectionView: self.collectionView) {
      (collectionView: NSCollectionView, indexPath: IndexPath, itemIdentifier: String) -> NSCollectionViewItem? in
      let item = collectionView.makeItem(withIdentifier: .postsGridItem, for: indexPath) as! PostsGridCollectionViewItem
      let post = self.listing?.post(withGlobalID: itemIdentifier)
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

    // Only ever append *new* posts into the snapshot. Appending existing items
    // results in a warning and the current selection being squashed if it's
    // nearby.
    let newPosts = latestChunk.filter { !snapshot.itemIdentifiers.contains($0.globalID) }

    guard !newPosts.isEmpty else {
      NSLog("not updating snapshot; all posts in the latest chunk were already within the snapshot")
      return
    }

    snapshot.appendItems(newPosts.map(\.globalID))
    self.dataSource.apply(snapshot, animatingDifferences: true)
  }
}
