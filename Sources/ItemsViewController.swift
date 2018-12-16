//
//  GenericTable.swift
//  SwiftBits
//
//  Created by Bart Whiteley on 11/27/16.
//  Copyright © 2018 SwiftBit. All rights reserved.
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

open class ItemsViewController<Item>: UITableViewController, UISearchResultsUpdating {
    public var items: [[Item]] = [] {
        didSet {
            filteredItems = items
        }
    }
    var filteredItems: [[Item]] = []
    let cellDescriptor: (Item) -> CellDescriptor
    public var didSelect: (Item) -> () = { _ in }
    var reuseIdentifiers: Set<String> = []
    
    // This makes it behave like Mail.app. Setting this to true will
    // override navigationItem.hidesSearchBarWhenScrolling
    public var showsSearchBarOnFirstLoadThenHidesWhenScrolling: Bool = false
    
    public let searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    // If you supply this closure it will add a search bar to the top of the table
    // and apply the provided filter function when filtering.
    public var searchFilter: ((String, Item) -> Bool)? {
        didSet {
            if searchFilter == nil {
                if #available(iOS 11.0, *) {
                    self.navigationItem.searchController = nil
                } else {
                    self.tableView.tableHeaderView = nil
                }
            }
            else {
                if #available(iOS 11.0, *) {
                    self.navigationItem.searchController = self.searchController
                } else {
                    self.tableView.tableHeaderView = self.searchController.searchBar
                }
            }
        }
    }
    
    public init(items: [[Item]], style: UITableViewStyle = .plain, cellDescriptor: @escaping (Item) -> CellDescriptor) {
        self.cellDescriptor = cellDescriptor
        super.init(style: style)
        self.items = items
        self.filteredItems = items
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchResultsUpdater = self
        self.definesPresentationContext = true // get rid of warning: The topViewController of the navigation controller containing the presented search controller must have definesPresentationContext set to YES. Also, if we don't do this the nav bar disappears when we pop :face_with_rolling_eyes:
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = filteredItems[indexPath.section][indexPath.row]
        
        self.didSelect(item)
    }
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return filteredItems.count
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredItems[section].count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = filteredItems[indexPath.section][indexPath.row]
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
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            if showsSearchBarOnFirstLoadThenHidesWhenScrolling {
                self.navigationItem.hidesSearchBarWhenScrolling = false
            }
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            if showsSearchBarOnFirstLoadThenHidesWhenScrolling {
                self.navigationItem.hidesSearchBarWhenScrolling = true
            }
        }
    }

    public func updateSearchResults(for searchController: UISearchController) {
        guard let filterFunc = self.searchFilter else { return }
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredItems = items
            tableView.reloadData()
            return
        }
        filteredItems = items.map { (subItems:[Item]) in
            return subItems.filter { filterFunc(searchText, $0) }
        }
        tableView.reloadData()
    }
}
