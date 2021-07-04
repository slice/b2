import Cocoa

extension PostsViewController {
  /// Update the collection view's layout according to user preferences.
  func makeCompositionalLayout() -> NSCollectionViewCompositionalLayout {
    let spacing = CGFloat(Preferences.shared.get(.imageGridSpacing))
    let size = CGFloat(Preferences.shared.get(.imageGridThumbnailSize))

    let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(size), heightDimension: .absolute(size))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    item.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(size))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)

    return NSCollectionViewCompositionalLayout(section: section)
  }

  func setupCollectionView() {
    self.collectionView.register(
      PostsGridCollectionViewItem.self, forItemWithIdentifier: .postsGridItem
    )
    self.collectionView.dataSource = self.dataSource
  }
}

extension PostsViewController: NSCollectionViewDelegate {
  func collectionView(
    _ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>
  ) {
    let lastIndexPath = indexPaths.max()!
    let item = collectionView.item(at: lastIndexPath) as! PostsGridCollectionViewItem
    self.onPostSelected?(item.post)
  }

  // Only load thumbnails as the user scrolls.
  func collectionView(
    _: NSCollectionView, willDisplay item: NSCollectionViewItem,
    forRepresentedObjectAt _: IndexPath
  ) {
    let postsGridItem = item as! PostsGridCollectionViewItem

    guard postsGridItem.customImageView.image == nil else {
      // Only load the image if we have yet to do so.
      return
    }

    self.thumbnailsQueue.async {
      guard let post = postsGridItem.post else {
        return
      }

      var image: NSImage
      do {
        image = try self.loadThumbnail(forPost: post)
      } catch {
        self.fetchLog.error(
          "failed to load thumbnail image for post (globalID: \(post.globalID, privacy: .public), error: \(error.localizedDescription, privacy: .public), URL: \(post.thumbnailImageURL, privacy: .public))"
        )
        guard let fallbackThumbnailImage = NSImage(data: self.loadFallbackThumbnailData()) else {
          fatalError("failed to create image from fallback thumbnail data (?)")
        }
        image = fallbackThumbnailImage
      }

      DispatchQueue.main.async {
        postsGridItem.customImageView.image = image
      }
    }
  }
}
