//
//  ASCSharingSettingsVerifyRightHoldersView.swift
//  Documents
//
//  Created by Павел Чернышев on 13.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

protocol ASCSharingSettingsVerifyRightHoldersViewDelegate: AnyObject {
    func onDoneBarBtnTapped()
}

class ASCSharingSettingsVerifyRightHoldersView {
    
    weak var view: UIView!
    weak var tableView: UITableView!
    weak var navigationController: UINavigationController?
    weak var navigationItem: UINavigationItem?
    weak var delegate: ASCSharingSettingsVerifyRightHoldersViewDelegate?
    
    private lazy var doneBarBtn: UIBarButtonItem = {
        return UIBarButtonItem(title: NSLocalizedString("Done", comment: ""),style: .done, target: self, action: #selector(onDoneBarBtnTapped))
    }()
    
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
        navigationController?.isToolbarHidden = true
        navigationItem?.rightBarButtonItem = doneBarBtn
    }
    
    private func configureTableView() {
        tableView.tableFooterView = UIView()
        if #available(iOS 15.0, *) {} else {
            tableView.backgroundColor = Asset.Colors.tableBackground.color
        }
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = 0
        tableView.tableHeaderView = UIView()
    }
}

//MARK: - Functions for delegate
extension ASCSharingSettingsVerifyRightHoldersView {
    @objc func onDoneBarBtnTapped() {
        delegate?.onDoneBarBtnTapped()
    }
}
