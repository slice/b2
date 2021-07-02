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
  var selectionColor: NSColor = .selectedContentBackgroundColor {
    didSet {
      self.cachedTintedImage = nil
      self.needsDisplay = true
    }
  }

  var contentsGravity: CALayerContentsGravity = .resizeAspect {
    didSet {
      self.needsDisplay = true
    }
  }

  var image: NSImage? {
    didSet {
      self.cachedTintedImage = nil
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

  // TODO: Is it possible to just use `draw` instead of `updateLayer` here?
  // Then we wouldn't have to tint the image at all; we could just draw a
  // semitransparent fill over the image.

  private var tintedImage: NSImage? {
    if self.cachedTintedImage == nil {
      self.cacheTintedImage()
    }

    return self.cachedTintedImage
  }

  private var cachedTintedImage: NSImage?

  private func cacheTintedImage() {
    guard let image = self.image else { return }
    self.cachedTintedImage = image.tinted(with: self.selectionColor)
  }

  override func updateLayer() {
    let color = self.isSelected ? self.selectionColor : NSColor.clear

    let layer = self.layer!
    layer.backgroundColor = color.cgColor
    layer.borderColor = color.cgColor
    layer.borderWidth = CGFloat(self.selectionBorderWidth)
    layer.contentsGravity = self.contentsGravity
    layer.contents = self.isSelected ? self.tintedImage : self.image
  }
}
