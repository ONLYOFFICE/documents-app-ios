//
//  ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    let tables:  [RightHoldersTableType: UITableView]
    
    init(tables: [RightHoldersTableType: UITableView]) {
        self.tables = tables
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        tables.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tableKey = Array(tables.keys)[section]
        guard let table = tables[tableKey] else { fatalError("couldn't find table by key \(tableKey)") }
        
        var count = 0
        for tableSection in 0..<table.numberOfSections {
            count += table.numberOfRows(inSection: tableSection)
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableKey = Array(tables.keys)[indexPath.section]
        guard let table = tables[tableKey] else { fatalError("couldn't find table by key \(tableKey)") }
        return findCell(inTable: table, byRowIndex: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let tableKey = Array(tables.keys)[section]
        return tableKey.getTitle()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    private func findCell(inTable table: UITableView, byRowIndex rowIndex: Int) -> UITableViewCell {
        var rowCounter = 0
        for section in 0..<table.numberOfSections {
            for row in 0..<table.numberOfRows(inSection: section) {
                if rowCounter == rowIndex {
                    
                    guard let cell = table.dataSource?.tableView(table, cellForRowAt: IndexPath(row: row, section: section)) else { return UITableViewCell() }
                    return cell
                }
                rowCounter += 1
            }
        }
        fatalError("Couldn't find the cell")
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: section) ?? ""
        header.contentView.backgroundColor = .white
        return header
    }
}
