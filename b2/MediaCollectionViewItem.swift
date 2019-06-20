import Cocoa

let images = [
    NSImage.colorPanelName,
    NSImage.infoName,
    NSImage.mobileMeName,
    NSImage.cautionName,
]

class MediaCollectionViewItem: NSCollectionViewItem {
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView!.image = NSImage(named: images.randomElement()!)
    }
}
