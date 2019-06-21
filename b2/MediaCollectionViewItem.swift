import Cocoa

class MediaCollectionViewItem: NSCollectionViewItem {
    override var isSelected: Bool {
        didSet {
            self.view.layer!.borderColor = self.isSelected ? NSColor.selectedControlColor.highlight(withLevel: 0.2)!.cgColor : NSColor.clear.cgColor
            self.view.layer!.backgroundColor = self.isSelected ? NSColor.selectedControlColor.cgColor : NSColor.quaternaryLabelColor.cgColor
        }
    }

    static func toolTipForFile(_ file: MediaFile) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        dateFormatter.doesRelativeDateFormatting = true

        let timestampHumanReadable = dateFormatter.string(from: file.metadata.timestamp)
        let sizeHumanReadable = ByteCountFormatter.string(fromByteCount: Int64(file.metadata.size), countStyle: .file)
        return "added \(timestampHumanReadable), \(sizeHumanReadable)"
    }

    var file: MediaFile! {
        didSet {
            let thumbnailPath = self.file.path(type: .thumbnail).string
            self.imageView!.image = NSImage(byReferencingFile: thumbnailPath)
            self.view.toolTip = MediaCollectionViewItem.toolTipForFile(self.file)
        }
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
