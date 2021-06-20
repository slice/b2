//
//  SelectableImageView.swift
//  b2
//
//  Created by slice on 6/18/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa

class SelectableImageView: NSView {
    var contentsGravity: CALayerContentsGravity = .resizeAspect {
        didSet {
            self.needsDisplay = true
        }
    }

    var image: NSImage? = nil {
        didSet {
            self.needsDisplay = true
        }
    }

    var selectionBorderWidth: Int = 10 {
        didSet {
            self.needsDisplay = true
        }
    }

    var isSelected: Bool = false {
        didSet {
            self.needsDisplay = true
        }
    }

    override var wantsUpdateLayer: Bool {
        true
    }

    override func updateLayer() {
        self.layer?.contentsGravity = self.contentsGravity
        self.layer?.contents = self.image
        self.layer?.borderWidth = CGFloat(self.selectionBorderWidth)
        let color = self.isSelected ? NSColor.selectedContentBackgroundColor.cgColor : NSColor.clear.cgColor
        self.layer?.backgroundColor = color
        self.layer?.borderColor = color
    }
}
