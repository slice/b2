import Cocoa

class ResizingTabViewController: NSTabViewController {
  override func tabView(_: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
    guard let tabViewItem = tabViewItem, let tabViewItemView = tabViewItem.view else { return }
    self.preferredContentSize = tabViewItemView.frame.size
  }
}
