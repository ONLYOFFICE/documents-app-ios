//
//  ASCSharingSettingsVerifyRightHoldersView.swift
//  Documents
//
//  Created by Павел Чернышев on 13.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

class ASCSharingSettingsVerifyRightHoldersView {
    
    weak var view: UIView!
    weak var tableView: UITableView!
    weak var navigationController: UINavigationController?
    weak var navigationItem: UINavigationItem?
    
    init(view: UIView, tableView: UITableView) {
        self.view = view
        self.tableView = tableView
    }
    
    func configure() {
        configureNavigationBar()
        configureTableView()
    }
    
    func reset() {
        tableView.reloadData()
    }
    
    private func configureNavigationBar() {
        navigationItem?.largeTitleDisplayMode = .never
        navigationController?.navigationBar.backItem?.backButtonTitle = NSLocalizedString("Back", comment: "")
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = NSLocalizedString("Done", comment: "")
        navigationController?.navigationBar.topItem?.title = NSLocalizedString("Sharing settings", comment: "")
        navigationController?.isToolbarHidden = true
    }
    
    private func configureTableView() {
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = Asset.Colors.tableBackground.color
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = 0
        tableView.tableHeaderView = UIView()
    }
}
