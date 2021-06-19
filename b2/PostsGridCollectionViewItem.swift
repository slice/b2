import Cocoa
import Path

class PostsGridCollectionViewItem: NSCollectionViewItem {
    var selectableImageView: SelectableImageView!

    override func loadView() {
        // The frame is determined by the collection view.
        self.selectableImageView = SelectableImageView(frame: .zero)
        self.view = self.selectableImageView
    }

    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            if self.isSelected {
                return
            }

            let isHighlighted = self.highlightState == .forSelection
            self.selectableImageView.isSelected = isHighlighted

        }
    }

    override var isSelected: Bool {
        didSet {
            self.selectableImageView.isSelected = self.isSelected
        }
    }

    /// The file that this item is associated with.
    ///
    /// The thumbnail of the file isn't loaded until you call `loadImage`.
    var file: BooruFile! {
        didSet {
            self.view.toolTip = self.toolTip()
        }
    }

    private func toolTip() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current

        let timestampHumanReadable = dateFormatter.string(from: self.file.createdAt)
        let sizeHumanReadable = ByteCountFormatter.string(
            fromByteCount: Int64(self.file.size),
            countStyle: .file
        )
        return "added \(timestampHumanReadable), \(sizeHumanReadable)"
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        if event.clickCount == 2 {
            NSWorkspace.shared.open(self.file.imageURL)
        }
    }

    override func prepareForReuse() {
        self.selectableImageView.isSelected = false
        self.selectableImageView.image = nil
    }
}
