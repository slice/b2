import Cocoa

private enum IndexDirection {
  case previous, next
}

class PostsGridCollectionView: NSCollectionView {
  override func moveRight(_: Any?) {
    let direction: IndexDirection = self.userInterfaceLayoutDirection == .leftToRight ? .next : .previous
    self.keyboardSelectItem(inDirection: direction)
  }

  override func moveLeft(_: Any?) {
    let direction: IndexDirection = self.userInterfaceLayoutDirection == .leftToRight ? .previous : .next
    self.keyboardSelectItem(inDirection: direction)
  }

  // Make sure to wrap around when using the horizontal arrow keys.
  private func keyboardSelectItem(inDirection direction: IndexDirection) {
    guard !self.selectionIndexPaths.isEmpty, let lastSelectedIndexPath = self.selectionIndexPaths.first else {
      return
    }

    let nextIndex = lastSelectedIndexPath.item + (direction == .next ? 1 : -1)
    let nextIndexPath = IndexPath(item: nextIndex, section: lastSelectedIndexPath.section)
    let maximumIndex = self.numberOfItems(inSection: lastSelectedIndexPath.section) - 1

    // Don't hit bounds.
    if (direction == .previous && nextIndex < 0) || (direction == .next && nextIndex > maximumIndex) {
      return
    }

    self.deselectItems(at: self.selectionIndexPaths)
    let nextIndexSet: Set<IndexPath> = [nextIndexPath]
    self.selectItems(at: nextIndexSet, scrollPosition: [.nearestVerticalEdge, .nearestHorizontalEdge])
    self.delegate?.collectionView?(self, didSelectItemsAt: nextIndexSet)
  }
}
