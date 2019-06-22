import Cocoa
import Path_swift

class WindowController: NSWindowController {
    @IBOutlet weak var tokenField: NSTokenField!
    var database: HydrusDatabase!
    var tab: WindowController?

    @IBAction func performSearch(_ sender: NSTokenField) {
        let viewController = self.contentViewController as! ViewController
        let tags = sender.objectValue as! [String]

        if tags.isEmpty {
            try! viewController.loadAllMedia()
        } else {
            NSLog("Searching for tags: \(tags)")
            try! viewController.performSearch(tags: tags)
        }
    }

    override func windowWillLoad() {
//        let path = Path.home / "Library" / "Hydrus"
        let path = Path.home / "hydrus" / "db"
        do {
            self.database = try HydrusDatabase(databasePath: path)
        } catch let error {
            let alert = NSAlert()
            alert.messageText = "Failed to load database"
            alert.informativeText = error.localizedDescription
            alert.runModal()
            NSApplication.shared.terminate(self)
        }
    }

    override func newWindowForTab(_ sender: Any?) {
        let controller = self.storyboard!.instantiateInitialController() as! WindowController
        self.window!.addTabbedWindow(controller.window!, ordered: .above)
        controller.window!.makeKeyAndOrderFront(self)
        self.tab = controller
    }
}
