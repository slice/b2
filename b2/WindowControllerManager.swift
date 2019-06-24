import Cocoa

class WindowControllerManager<T: NSWindowController>: NSObject, NSWindowDelegate {
    var windows: [T] = []

    func add(_ controller: T) {
        windows.append(controller)
    }

    func windowWillClose(_ notification: Notification) {
        let window = notification.object as! NSWindow
        let controller = window.windowController as! T

        if let index = self.windows.firstIndex(of: controller) {
            self.windows.remove(at: index)
        } else {
            NSLog("WindowReferenceManager: Cannot find \(controller) (window: \(window))")
        }
    }
}
