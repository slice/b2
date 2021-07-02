import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  var preferencesWindowController = PreferencesWindowController()

  @IBAction func openPreferences(_: Any) {
    self.preferencesWindowController.showWindow(nil)
  }

  func applicationDidFinishLaunching(_: Notification) {
    NSLog("\u{1f986} quack quack")
    B2Error.setupUserInfoValueProvider()
  }

  func applicationWillTerminate(_: Notification) {}
}
