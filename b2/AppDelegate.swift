import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  var preferencesWindowController = PreferencesWindowController()

  @IBAction func openPreferences(_ sender: Any) {
    self.preferencesWindowController.showWindow(nil)
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSLog("\u{1f986} quack quack")
  }

  func applicationWillTerminate(_ aNotification: Notification) {

  }
}
