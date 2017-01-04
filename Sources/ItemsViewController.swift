//
//  GenericTable.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 11/27/16.
//  Copyright © 2016 SwiftBit. All rights reserved.
//

// https://talk.objc.io/episodes/S01E26-generic-table-view-controllers-part-2

import UIKit

public struct CellDescriptor {
    let cellClass: UITableViewCell.Type
    let reuseIdentifier: String
    let configure: (UITableViewCell) -> ()
    let nib: UINib?
    
    public init<Cell: UITableViewCell>(reuseIdentifier: String, nib: UINib? = nil, configure: @escaping (Cell) -> ()) {
        self.cellClass = Cell.self
        self.reuseIdentifier = reuseIdentifier
        self.nib = nib
        self.configure = { cell in
            configure(cell as! Cell)
        }
    }
}

open class ItemsViewController<Item>: UITableViewController {
    public var items: [[Item]] = []
    let cellDescriptor: (Item) -> CellDescriptor
    public var didSelect: (Item) -> () = { _ in }
    var reuseIdentifiers: Set<String> = []
    
    public init(items: [[Item]], style: UITableViewStyle = .plain, cellDescriptor: @escaping (Item) -> CellDescriptor) {
        self.cellDescriptor = cellDescriptor
        super.init(style: style)
        self.items = items
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.section][indexPath.row]
        didSelect(item)
    }
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section][indexPath.row]
        let descriptor = cellDescriptor(item)
        
        if !reuseIdentifiers.contains(descriptor.reuseIdentifier) {
            if let nib = descriptor.nib {
                tableView.register(nib, forCellReuseIdentifier: descriptor.reuseIdentifier)
            } else {
                tableView.register(descriptor.cellClass, forCellReuseIdentifier: descriptor.reuseIdentifier)
            }
            reuseIdentifiers.insert(descriptor.reuseIdentifier)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: descriptor.reuseIdentifier, for: indexPath)
        descriptor.configure(cell)
        return cell
    }
}

