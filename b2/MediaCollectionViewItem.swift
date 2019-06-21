import Cocoa

class MediaCollectionViewItem: NSCollectionViewItem {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer!.backgroundColor = NSColor.quaternaryLabelColor.cgColor
    }
}
