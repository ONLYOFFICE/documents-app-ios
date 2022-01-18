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
        let sourceTableView = getSourceTable(bySectionIdex: section)
        
        var count = 0
        for tableSection in 0..<sourceTableView.numberOfSections {
            count += sourceTableView.numberOfRows(inSection: tableSection)
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sourceTableView = getSourceTable(bySectionIdex: indexPath.section)
        return getSourceCell(inTable: sourceTableView, byRowIndex: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let sourceTableView = getSourceTable(bySectionIdex: indexPath.section)
        let findedCell = getSourceCell(inTable: sourceTableView, byRowIndex: indexPath.row)
        if findedCell.isSelected {
            cell.setSelected(true, animated: false)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sourceTableView = getSourceTable(bySectionIdex: indexPath.section)
        let sourceRowIndexPath = getSourceRowIndexPath(inTableView: sourceTableView, byRowIndex: indexPath.row)

        let _ = sourceTableView.delegate?.tableView?(sourceTableView, willSelectRowAt: sourceRowIndexPath)
        sourceTableView.selectRow(at: sourceRowIndexPath, animated: false, scrollPosition: .none)
        sourceTableView.delegate?.tableView?(sourceTableView, didSelectRowAt: sourceRowIndexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let sourceTableView = getSourceTable(bySectionIdex: indexPath.section)
        let sourceRowIndexPath = getSourceRowIndexPath(inTableView: sourceTableView, byRowIndex: indexPath.row)
        
        let _ = sourceTableView.delegate?.tableView?(sourceTableView, willDeselectRowAt: sourceRowIndexPath)
        sourceTableView.deselectRow(at: sourceRowIndexPath, animated: false)
        sourceTableView.delegate?.tableView?(sourceTableView, didDeselectRowAt: sourceRowIndexPath)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let tableKey = Array(tables.keys)[section]
        let numberOfRows = self.tableView(tableView, numberOfRowsInSection: section)
        return numberOfRows > 0 ? tableKey.getTitle() : nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let numberOfRows = self.tableView(tableView, numberOfRowsInSection: section)
        return numberOfRows > 0 ? 38 : CGFloat.zero
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: section) ?? ""

        if #available(iOS 13.0, *) {
            header.contentView.backgroundColor = .systemBackground
        } else {
            header.contentView.backgroundColor = .white
        }
        
        return header
    }
    
    private func getSourceTable(bySectionIdex sectionIdex: Int) -> UITableView {
        let tableKey = Array(tables.keys)[sectionIdex]
        guard let tableView = tables[tableKey] else { fatalError("couldn't find table by key \(tableKey)") }
        return tableView
    }
    
    private func getSourceCell(inTable tableView: UITableView, byRowIndex rowIndex: Int) -> UITableViewCell {

        let indexPath = getSourceRowIndexPath(inTableView: tableView, byRowIndex: rowIndex)
        guard
            let cell = tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
        else { fatalError("Couldn't find the cell") }
        
        return cell
    }
    
    private func getSourceRowIndexPath(inTableView tableView: UITableView,  byRowIndex rowIndex: Int) -> IndexPath {
        var rowCounter = 0
        for section in 0..<tableView.numberOfSections {
            for row in 0..<tableView.numberOfRows(inSection: section) {
                if rowCounter == rowIndex {
                    return IndexPath(row: row, section: section)
                }
                rowCounter += 1
            }
        }
        fatalError("Couldn't find the index path for row index \(rowIndex)")
    }
}
