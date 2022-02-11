//
//  ASCSharingOptionsAccessViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingSettingsAccessViewController: ASCBaseTableViewController {
    var reuseCellId = "basicStyle"
    
    var viewModel: ASCSharingSettingsAccessViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            
            self.title = viewModel.title
            
            if isViewLoaded {
                configureNavigationBar()
            }
            
            guard let accessProvider = viewModel.accessProvider else { return }
            
            accessList = accessProvider.get().sorted(by: { $0.getSortWeight() < $1.getSortWeight() })
            
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }

    var heightForSectionHeader: CGFloat = 38
    
    private var accessList: [ASCShareAccess] = []
    
    init() {
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        configureNavigationBar()
        configureTableView()
    }
    
    private func configureNavigationBar() {
        navigationItem.largeTitleDisplayMode = viewModel?.largeTitleDisplayMode ?? .automatic
    }
    
    private func configureTableView() {
        tableView.tableFooterView = UIView()
        if #available(iOS 15.0, *) {} else {
            tableView.backgroundColor = Asset.Colors.tableBackground.color
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseCellId)
    }
}

// MARK: - TableView data source and delegate
extension ASCSharingSettingsAccessViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        accessList.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseCellId, for: indexPath)
        let access = accessList[indexPath.row]
        cell.imageView?.image = access.image()
        cell.textLabel?.text = access.title()
        cell.accessoryType = access == viewModel?.currentlyAccess ? .checkmark : .none
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let access = accessList[indexPath.row]
        if viewModel?.currentlyAccess != access {
            viewModel?.currentlyAccess = access
            tableView.reloadData()
            self.viewModel?.selectAccessDelegate?(access)
            if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel?.headerText
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let access = viewModel?.currentlyAccess else { return nil }
        return viewModel?.accessNoteProvider?.get(for: access)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        heightForSectionHeader
    }
    
}
