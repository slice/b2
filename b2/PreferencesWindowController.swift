//
//  PreferencesWindowController.swift
//  b2
//
//  Created by slice on 6/19/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {
  convenience init() {
    self.init(windowNibName: "")
  }

  lazy var tabViewController: ResizingTabViewController = {
    let tabVC = ResizingTabViewController()

    let appearanceItem = NSTabViewItem(viewController: AppearanceSettingsViewController())
    appearanceItem.label = "Appearance"
    appearanceItem.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Appearance")
    tabVC.addTabViewItem(appearanceItem)

    let boorusItem = NSTabViewItem(viewController: BooruSettingsViewController())
    boorusItem.label = "Boorus"
    boorusItem.image = NSImage(
      systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "Boorus")
    tabVC.addTabViewItem(boorusItem)

    tabVC.tabStyle = .toolbar
    return tabVC
  }()

  override func loadWindow() {
    self.window = NSWindow(
      contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
    self.window?.title = "Preferences"
  }

  override func windowDidLoad() {
    super.windowDidLoad()
    self.contentViewController = self.tabViewController
  }
}
