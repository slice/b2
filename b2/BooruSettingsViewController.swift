//
//  BooruSettingsViewController.swift
//  b2
//
//  Created by slice on 6/16/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa

class BooruSettingsViewController: NSViewController {
    lazy var containerView: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 400).isActive = true
        view.heightAnchor.constraint(equalToConstant: 400).isActive = true
        return view
    }()

    override func loadView() {
        self.view = self.containerView

        let placeholderButton = NSButton(title: "🦆", target: nil, action: nil)
        placeholderButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(placeholderButton)
        NSLayoutConstraint.activate([
            placeholderButton.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor),
            placeholderButton.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor)
        ])
    }
}
