import Cocoa
import Path_swift

class MediaCollectionViewItem: NSCollectionViewItem {
    override var isSelected: Bool {
        didSet {
            self.view.layer!.borderColor = self.isSelected
                ? NSColor.selectedContentBackgroundColor.cgColor
                : NSColor.clear.cgColor

            self.view.layer!.backgroundColor = self.isSelected
                ? NSColor.selectedContentBackgroundColor.cgColor
                : NSColor.quaternaryLabelColor.cgColor
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

    /// Loads the thumbnail image into the item's `imageView`.
    func loadThumbnail() {
        let data = try! Data(contentsOf: self.file.thumbnailImageURL)
        self.imageView!.image = NSImage(data: data)!
    }

    private func toolTip() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        dateFormatter.doesRelativeDateFormatting = true

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
        self.view.layer!.backgroundColor = NSColor.quaternaryLabelColor.cgColor
    }
}
