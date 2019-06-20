import Cocoa

class WindowController: NSWindowController {
    var subwindow: WindowController?

    @IBAction override func newWindowForTab(_ sender: Any?) {
        let controller = storyboard!.instantiateInitialController() as! WindowController
        window!.addTabbedWindow(controller.window!, ordered: .above)
        controller.window!.orderFront(self)
        // Keep a reference to the controller to keep it alive.
        subwindow = controller
    }
}
