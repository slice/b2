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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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
