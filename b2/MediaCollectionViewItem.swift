import Cocoa

class MediaCollectionViewItem: NSCollectionViewItem {
    var file: MediaFile! {
        didSet {
            let thumbnailPath = self.file.path(type: .thumbnail).string
            self.imageView!.image = NSImage(byReferencingFile: thumbnailPath)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer!.backgroundColor = NSColor.quaternaryLabelColor.cgColor
    }
}
