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

// MARK: Actions

extension PostsGridCollectionView {
  private var selectedPosts: [BooruPost] {
    self.selectionIndexes.compactMap { index in
      (self.item(at: index) as? PostsGridCollectionViewItem)?.post
    }
  }

  @objc func openPost(_ sender: Any?) {
    self.selectedPosts
      .compactMap(\.postURL)
      .forEach { NSWorkspace.shared.open($0) }
  }

  @objc func openPostMedia(_ sender: Any?) {
    self.selectedPosts
      .map(\.imageURL)
      .forEach { NSWorkspace.shared.open($0) }
  }
}

extension PostsGridCollectionView: NSMenuItemValidation {
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    let nothingSelected = self.selectionIndexes.isEmpty

    switch menuItem.action {
    case #selector(openPost(_:)):
      if nothingSelected { return false }
      return !self.selectedPosts.compactMap(\.postURL).isEmpty
    case #selector(openPostMedia(_:)):
      return !nothingSelected
    default:
      return true
    }
  }
}

// MARK: Menus

extension PostsGridCollectionView {

  @objc func openPostFromMenu(_ sender: NSMenuItem?) {
    guard let post = sender?.representedObject as? BooruPost,
          let postURL = post.postURL else {
      return
    }

    NSWorkspace.shared.open(postURL)
  }

  @objc func openPostMediaFromMenu(_ sender: NSMenuItem?) {
    guard let post = sender?.representedObject as? BooruPost else {
      return
    }

    NSWorkspace.shared.open(post.imageURL)
  }

  override func menu(for event: NSEvent) -> NSMenu? {
    let point = self.convert(event.locationInWindow, from: nil)
    guard let indexPath = self.indexPathForItem(at: point),
          let item = self.item(at: indexPath) as? PostsGridCollectionViewItem,
          let post = item.post else {
      NSLog("failed to show menu for posts grid right click >:(")
      return nil
    }
    let menu = NSMenu()

    let openPostMenuItem = NSMenuItem(title: "Open Post", action: #selector(openPostFromMenu(_:)), keyEquivalent: "o")
    openPostMenuItem.representedObject = post
    openPostMenuItem.isEnabled = post.postURL != nil
    menu.addItem(openPostMenuItem)

    let openPostMediaMenuItem = NSMenuItem(title: "Open Post Media", action: #selector(openPostMediaFromMenu(_:)), keyEquivalent: "O")
    openPostMediaMenuItem.representedObject = post
    menu.addItem(openPostMediaMenuItem)

    return menu
  }
}
