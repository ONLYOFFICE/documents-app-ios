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
    
    var selectAccessDelegate: ((ASCShareAccess) -> Void)?
    
    var currentlyAccess: ASCShareAccess? = .read
    var accessProvider: ASCSharingSettingsAccessProvider = ASCSharingSettingsAccessDefaultProvider() {
        didSet {
            accessList = accessProvider.get().sorted(by: { $0.getSortWeight() < $1.getSortWeight() })
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }
    
    var heightForSectionHeader: CGFloat = 38
    
    var largeTitleDisplayMode:  UINavigationItem.LargeTitleDisplayMode = .automatic
    var headerText: String = NSLocalizedString("Access settings", comment: "")
    var footerText: String = NSLocalizedString("Unauthorized users will not be able to view the document.", comment: "")
    
    private var accessList: [ASCShareAccess] = []
    
    override init(style: UITableView.Style = .grouped) {
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        configureNavigationBar()
        configureTableView()
    }
    
    private func configureNavigationBar() {
        navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
        navigationController?.navigationBar.backIndicatorImage = UIImage()
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage()
        navigationController?.navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.leftBarButtonItem = nil;
        navigationItem.hidesBackButton = true
    }
    
    private func configureTableView() {
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = Asset.Colors.tableBackground.color
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
        cell.textLabel?.text = access.title()
        cell.accessoryType = access == currentlyAccess ? .checkmark : .none
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let access = accessList[indexPath.row]
        if currentlyAccess != access {
            currentlyAccess = access
            tableView.reloadData()
            self.selectAccessDelegate?(access)
            if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        headerText
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        footerText
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        heightForSectionHeader
    }
    
}
