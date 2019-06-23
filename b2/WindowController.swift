import Cocoa
import Path_swift

class WindowController: NSWindowController {
    @IBOutlet weak var tokenField: NSTokenField!
    var tab: WindowController?

    @IBAction func performSearch(_ sender: NSTokenField) {
        let viewController = self.contentViewController as! ViewController
        let tags = sender.objectValue as! [String]

        if tags.isEmpty {
            viewController.loadAllFilesAsync()
        } else {
            NSLog("Searching for tags: \(tags)")
            try! viewController.performSearch(tags: tags)
        }
    }

    override func newWindowForTab(_ sender: Any?) {
        let controller = self.storyboard!.instantiateInitialController() as! WindowController
        self.window!.addTabbedWindow(controller.window!, ordered: .above)
        controller.window!.makeKeyAndOrderFront(self)
        self.tab = controller
    }
}
