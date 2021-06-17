//
//  AppearanceSettingsViewController.swift
//  b2
//
//  Created by slice on 6/16/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa

class AppearanceSettingsViewController: NSViewController {
    @IBOutlet weak var imageGridThumbnailSizeSlider: NSSlider!
    @IBOutlet weak var imageGridSpacingSlider: NSSlider!
    @IBOutlet weak var smallTagsCheckbox: NSButton!

    override func viewDidLoad() {
        let p = Preferences.shared
        self.imageGridThumbnailSizeSlider.integerValue = p.get(.imageGridThumbnailSize)
        self.imageGridSpacingSlider.integerValue = p.get(.imageGridSpacing)
        self.smallTagsCheckbox.state = p.get(.smallTagsEnabled) ? .on : .off
    }

    @IBAction private func action(sender: Any?) {
        let p = Preferences.shared
        p.set(.imageGridThumbnailSize, to: self.imageGridThumbnailSizeSlider.integerValue)
        p.set(.imageGridSpacing, to: self.imageGridSpacingSlider.integerValue)
        p.set(.smallTagsEnabled, to: self.smallTagsCheckbox.state == .on)
    }

    override func awakeFromNib() {
    }
}
