//
//  TagsViewController.swift
//  b2
//
//  Created by slice on 6/6/21.
//  Copyright © 2021 slice. All rights reserved.
//

import Cocoa

class TagsViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    var tags: [BooruTag] = []

    private var defaultsObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateSizing()

        self.defaultsObserver = NotificationCenter.default.addObserver(forName: .preferencesChanged, object: nil, queue: nil) { [weak self] _ in
            self?.updateSizing()
        }
    }

    private func updateSizing() {
        let smallTagsEnabled: Bool = Preferences.shared.get(.smallTagsEnabled)
        // Refer to macOS HIG.
        // TODO: Maybe don't hardcode these. Use row styles?
        self.tableView.rowHeight = smallTagsEnabled ? 17 : 24
    }

    deinit {
        if let observer = self.defaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension TagsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.tags.count
    }
}

extension TagsViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TagCell"), owner: nil) as! NSTableCellView
        let tag = self.tags[row]
        cell.textField!.stringValue = tag.description
        return cell
    }
}
