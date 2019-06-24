import Cocoa
import Path_swift

class MainWindowController: NSWindowController {
    @IBOutlet weak var tokenField: NSTokenField!
    var createdTab: MainWindowController?
    var createdWindow: MainWindowController?

    @IBAction func performSearch(_ sender: NSTokenField) {
        let viewController = self.contentViewController as! MainViewController
        let tags = sender.objectValue as! [String]

        if tags.isEmpty {
            viewController.loadAllFilesAsync()
        } else {
            NSLog("Searching for tags: \(tags)")
            try! viewController.performSearch(tags: tags)
        }
    }

    override func newWindowForTab(_ sender: Any?) {
        let controller = MainWindowController(windowNibName: self.windowNibName!)
        self.window!.addTabbedWindow(controller.window!, ordered: .above)
        controller.window!.makeKeyAndOrderFront(self)
        self.createdTab = controller
    }
}
