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

        let placeholder = NSTextField(labelWithString: "placeholder")
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(placeholder)
        NSLayoutConstraint.activate([
            placeholder.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor),
            placeholder.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor)
        ])
    }
}
