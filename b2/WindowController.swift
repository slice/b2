import Cocoa
import Path_swift

class WindowController: NSWindowController {
    var database: MediaDatabase!
    var tab: WindowController?

    override func windowWillLoad() {
        let path = Path.home / "hydrus" / "db"
        do {
            database = try MediaDatabase(databasePath: path)
        } catch let error {
            let alert = NSAlert()
            alert.messageText = "Failed to load database"
            alert.informativeText = error.localizedDescription
            alert.runModal()
            NSApplication.shared.terminate(self)
        }
    }

    override func newWindowForTab(_ sender: Any?) {
        let controller = storyboard!.instantiateInitialController() as! WindowController
        window!.addTabbedWindow(controller.window!, ordered: .above)
        controller.window!.makeKeyAndOrderFront(self)
        tab = controller
    }
}
