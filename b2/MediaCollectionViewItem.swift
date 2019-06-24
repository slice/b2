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

    var file: HydrusFile! {
        didSet {
            self.setupImage(path: self.file.path(type: .thumbnail))
            self.view.toolTip = self.toolTip()
        }
    }

    private func setupImage(path: Path) {
        // We manually read the file instead of passing the path because
        // thumbnails have a .thumbnail extension, which bugs out AppKit as it
        // tries to guess what type of image it is.
        if let data = try? Data(contentsOf: path) {
            self.imageView!.image = NSImage(data: data)
        } else {
            NSLog("Cannot setup image; failed to read \(path).")
        }
    }

    private func toolTip() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        dateFormatter.doesRelativeDateFormatting = true

        let timestampHumanReadable = dateFormatter.string(from: self.file.metadata.timestamp)
        let sizeHumanReadable = ByteCountFormatter.string(
            fromByteCount: Int64(self.file.metadata.size),
            countStyle: .file
        )
        return "added \(timestampHumanReadable), \(sizeHumanReadable)"
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        if event.clickCount == 2 {
            NSWorkspace.shared.openFile(self.file.path().string)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer!.borderWidth = 1
        self.view.layer!.borderColor = NSColor.clear.cgColor
        self.view.layer!.backgroundColor = NSColor.quaternaryLabelColor.cgColor
    }
}
