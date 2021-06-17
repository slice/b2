import Cocoa
import Path

class MediaCollectionViewItem: NSCollectionViewItem {
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            if self.isSelected {
                return
            }

            let isHighlighted = self.highlightState == .forSelection
            self.updateAppearance(isHighlighted: isHighlighted)
        }
    }

    override var isSelected: Bool {
        didSet {
            self.updateAppearance(isHighlighted: self.isSelected)
        }
    }

    private func updateAppearance(isHighlighted: Bool) {
        let color = isHighlighted ? NSColor.selectedContentBackgroundColor.cgColor : NSColor.clear.cgColor
        self.view.layer?.borderColor = color
        self.view.layer?.backgroundColor = color
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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer!.borderWidth = 3
        self.view.layer!.borderColor = NSColor.clear.cgColor
        self.view.layer!.backgroundColor = NSColor.clear.cgColor
    }

    override func prepareForReuse() {
        self.imageView?.image = nil
    }
}
