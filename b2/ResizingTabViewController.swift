//
//  ResizingTabViewController.swift
//  b2
//
//  Created by slice on 6/20/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa

class ResizingTabViewController: NSTabViewController {
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        guard let tabViewItem = tabViewItem, let tabViewItemView = tabViewItem.view else { return }
        self.preferredContentSize = tabViewItemView.frame.size
    }
}
