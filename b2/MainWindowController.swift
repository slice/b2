import Cocoa
import Path_swift

class MainWindowController: NSWindowController {
    @IBOutlet weak var tokenField: NSTokenField!
    @IBOutlet weak var viewController: MainViewController!
    var createdTab: MainWindowController?
    var createdWindow: MainWindowController?

    @IBAction func performSearch(_ sender: NSTokenField) {
        let tags = sender.objectValue as! [String]

        if tags.isEmpty {
            self.viewController.loadAllFilesAsync()
        } else {
            NSLog("Searching for tags: \(tags)")
            self.viewController.searchAsync(tags: tags)
        }
    }

    override func newWindowForTab(_ sender: Any?) {
        let controller = MainWindowController(windowNibName: self.windowNibName!)
        self.window!.addTabbedWindow(controller.window!, ordered: .above)
        controller.window!.makeKeyAndOrderFront(self)
        self.createdTab = controller
    }
}
