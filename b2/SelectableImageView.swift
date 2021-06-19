//
//  SelectableImageView.swift
//  b2
//
//  Created by slice on 6/18/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa

class SelectableImageView: NSView {
    var image: NSImage? = nil {
        didSet {
            self.needsDisplay = true
        }
    }

    var selectionBorderWidth: Int = 3 {
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
        // Resize the image to fit within the frame bounds.
        // TODO: Make this configurable by the user?
        self.layer?.contentsGravity = .resizeAspect
        self.layer?.contents = self.image
        self.layer?.borderWidth = CGFloat(self.selectionBorderWidth)
        let color = self.isSelected ? NSColor.selectedContentBackgroundColor.cgColor : NSColor.clear.cgColor
        self.layer?.backgroundColor = color
        self.layer?.borderColor = color
    }
}
