import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("\u{1f986} quack quack")
    }

    func applicationWillTerminate(_ aNotification: Notification) {

    }
}
