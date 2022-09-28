//
//  UITableView+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 07.06.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UITableView {
    /// Refresh header title of TableView
    /// - Parameter section: Number of section
    func refreshHeaderTitle(inSection section: Int) {
        UIView.setAnimationsEnabled(false)
        beginUpdates()

        let headerView = self.headerView(forSection: section)
        headerView?.textLabel?.text = dataSource?.tableView?(self, titleForHeaderInSection: section)?.uppercased()
        headerView?.sizeToFit()

        endUpdates()
        UIView.setAnimationsEnabled(true)
    }

    /// Refresh footer title of TableView
    /// - Parameter section: Number of section
    func refreshFooterTitle(inSection section: Int) {
        UIView.setAnimationsEnabled(false)
        beginUpdates()

        let footerView = self.footerView(forSection: section)
        footerView?.textLabel?.text = dataSource?.tableView?(self, titleForFooterInSection: section)
        footerView?.sizeToFit()

        endUpdates()
        UIView.setAnimationsEnabled(true)
    }

    /// Refresh header and footer title of all sections of TableView
    func refreshAllHeaderAndFooterTitles() {
        for section in 0 ..< numberOfSections {
            refreshHeaderTitle(inSection: section)
            refreshFooterTitle(inSection: section)
        }
    }
}
