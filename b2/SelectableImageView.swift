//
//  SelectableImageView.swift
//  b2
//
//  Created by slice on 6/18/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        guard let tinted = self.copy() as? NSImage else { return self }

        tinted.lockFocus()
            color.withAlphaComponent(0.5).set()
            NSRect(origin: .zero, size: self.size).fill()
        tinted.unlockFocus()

        return tinted
    }
}

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
        let color = self.isSelected ? NSColor.selectedContentBackgroundColor : NSColor.clear

        let layer = self.layer!
        layer.backgroundColor = color.cgColor
        layer.borderColor = color.cgColor
        layer.borderWidth = CGFloat(self.selectionBorderWidth)
        layer.contentsGravity = self.contentsGravity
        layer.contents = self.isSelected ? self.image?.tinted(with: color) : image
    }
}
