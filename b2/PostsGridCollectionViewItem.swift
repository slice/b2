import Cocoa
import Path

class PostsGridCollectionViewItem: NSCollectionViewItem {
  private var boxView: NSBox!
  var customImageView: NSImageView!

  override func loadView() {
    // The frame is determined by the collection view.
    self.boxView = NSBox(frame: .zero)
    self.boxView.isTransparent = true
    self.boxView.boxType = .custom
    self.boxView.borderWidth = 1
    self.boxView.borderColor = .selectedContentBackgroundColor.blended(withFraction: 0.25, of: .white) ?? .selectedContentBackgroundColor
    self.boxView.fillColor = .selectedContentBackgroundColor

    self.customImageView = NSImageView(frame: .zero)
    self.customImageView.imageScaling = .scaleProportionallyUpOrDown
    self.customImageView.translatesAutoresizingMaskIntoConstraints = false
    self.boxView.addSubview(self.customImageView)
    NSLayoutConstraint.activate([
      self.customImageView.topAnchor.constraint(equalTo: self.boxView.topAnchor),
      self.customImageView.leftAnchor.constraint(equalTo: self.boxView.leftAnchor),
      self.customImageView.rightAnchor.constraint(equalTo: self.boxView.rightAnchor),
      self.customImageView.bottomAnchor.constraint(equalTo: self.boxView.bottomAnchor),
    ])

    self.view = self.boxView
  }

  override var highlightState: NSCollectionViewItem.HighlightState {
    didSet {
      // Make the item immediately appear selected if we're being
      // highlighted for selection, instead of waiting for the selection
      // to be finalized. (This means that we get immediate visual
      // feedback when clicking.)
      //
      // Ignore this if we're already selected, except for when we're
      // being deselected.
      if self.isSelected, self.highlightState != .forDeselection {
        return
      }

      let isHighlighted = self.highlightState == .forSelection
      self.boxView.isTransparent = !isHighlighted
    }
  }

  override var isSelected: Bool {
    didSet {
      self.boxView.isTransparent = !self.isSelected
    }
  }

  /// The post that this item is associated with.
  var post: BooruPost! {
    didSet {
      self.view.toolTip = self.toolTip()
    }
  }

  private func toolTip() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    dateFormatter.locale = Locale.current

    let timestampHumanReadable = dateFormatter.string(from: self.post.createdAt)
    let sizeHumanReadable = ByteCountFormatter.string(
      fromByteCount: Int64(self.post.size),
      countStyle: .file
    )
    return "added \(timestampHumanReadable), \(sizeHumanReadable)"
  }

  override func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)

    if event.clickCount == 2 {
      NSWorkspace.shared.open(self.post.imageURL)
    }
  }

  override func prepareForReuse() {
    self.boxView.isTransparent = true
    self.customImageView.image = nil
  }
}
