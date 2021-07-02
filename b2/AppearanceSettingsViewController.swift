import Cocoa

class AppearanceSettingsViewController: NSViewController {
  lazy var imageGridThumbnailSizeSlider: NSSlider = {
    let slider = NSSlider(
      value: 0, minValue: 50, maxValue: 500, target: self, action: #selector(action)
    )
    slider.widthAnchor.constraint(equalToConstant: 200).isActive = true
    slider.numberOfTickMarks = 5
    return slider
  }()

  lazy var imageGridSpacingSlider: NSSlider = {
    let slider = NSSlider(
      value: 0, minValue: 0, maxValue: 100, target: self, action: #selector(action)
    )
    slider.translatesAutoresizingMaskIntoConstraints = false
    slider.widthAnchor.constraint(equalToConstant: 200).isActive = true
    slider.numberOfTickMarks = 5
    return slider
  }()

  lazy var imageGridScalingPopUpButton: NSPopUpButton = {
    let button = NSPopUpButton()
    let resizeToFitItem = NSMenuItem(
      title: "Resize to fit", action: #selector(action), keyEquivalent: ""
    )
    resizeToFitItem.tag = PostsGridScalingMode.resizeToFit.rawValue
    button.menu?.addItem(resizeToFitItem)
    let fillItem = NSMenuItem(title: "Fill", action: #selector(action), keyEquivalent: "")
    fillItem.tag = PostsGridScalingMode.fill.rawValue
    button.menu?.addItem(fillItem)
    return button
  }()

  lazy var compactTagsCheckbox: NSButton = {
    NSButton(checkboxWithTitle: "Compact tags", target: nil, action: #selector(action))
  }()

  lazy var settingsGridView: NSGridView = {
    let gridView = NSGridView(views: [
      [NSTextField(labelWithString: "Grid thumbnail size:"), self.imageGridThumbnailSizeSlider],
      [NSTextField(labelWithString: "Grid spacing:"), self.imageGridSpacingSlider],
      [NSTextField(labelWithString: "Grid thumbnail scaling:"), self.imageGridScalingPopUpButton],
      [NSView(), self.compactTagsCheckbox],
    ])
    gridView.translatesAutoresizingMaskIntoConstraints = false

    gridView.column(at: 0).xPlacement = .trailing
    gridView.columnSpacing = 10

    return gridView
  }()

  lazy var containerView: NSView = {
    let view = NSView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.widthAnchor.constraint(equalToConstant: 400).isActive = true
    view.heightAnchor.constraint(equalToConstant: 200).isActive = true
    return view
  }()

  override func loadView() {
    self.view = self.containerView

    self.containerView.addSubview(self.settingsGridView)
    NSLayoutConstraint.activate([
      self.settingsGridView.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor),
      self.settingsGridView.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor),
    ])
  }

  override func viewDidLoad() {
    let p = Preferences.shared
    self.imageGridThumbnailSizeSlider.integerValue = p.get(.imageGridThumbnailSize)
    self.imageGridSpacingSlider.integerValue = p.get(.imageGridSpacing)
    self.compactTagsCheckbox.state = p.get(.compactTagsEnabled) ? .on : .off
    self.imageGridScalingPopUpButton.selectItem(withTag: p.get(.imageGridScalingMode))
  }

  @IBAction private func action(sender _: Any?) {
    let p = Preferences.shared
    p.set(.imageGridThumbnailSize, to: self.imageGridThumbnailSizeSlider.integerValue)
    p.set(.imageGridSpacing, to: self.imageGridSpacingSlider.integerValue)
    p.set(.compactTagsEnabled, to: self.compactTagsCheckbox.state == .on)
    p.set(.imageGridScalingMode, to: self.imageGridScalingPopUpButton.selectedItem!.tag)
  }
}
