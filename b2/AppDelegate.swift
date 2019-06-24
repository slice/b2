import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static let mainWindowNibName = "MainWindow"

    var windowReferenceManager: WindowControllerManager = WindowControllerManager()

    @objc func newWindow(_ sender: Any) {
        let controller = MainWindowController(windowNibName: AppDelegate.mainWindowNibName)
        controller.showWindow(self)
        controller.window!.delegate = self.windowReferenceManager
        self.windowReferenceManager.add(controller)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let controller = MainWindowController(windowNibName: AppDelegate.mainWindowNibName)
        controller.window!.makeKeyAndOrderFront(self)
        controller.window!.delegate = self.windowReferenceManager
        self.windowReferenceManager.add(controller)
    }

    func applicationWillTerminate(_ aNotification: Notification) {

    }
}
