//
//  ASCSharingOptionsAccessViewController.swift
//  Documents
//
//  Created by Павел Чернышев on 15.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingOptionsAccessViewController: ASCBaseTableViewController {
    var reuseCellId = "basicStyle"
    
    var currentlyAccess: ASCShareAccess? = .read
    
    var accessList: [ASCShareAccess] = ASCShareAccess.allCases.filter({ $0 != .none })
    
    var heightForSectionHeader: CGFloat = 38
    
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
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.backIndicatorImage = UIImage()
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage()
        navigationController?.navigationBar.topItem?.title = NSLocalizedString("Sharing settings", comment: "")
    }
    
    private func configureTableView() {
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = Asset.Colors.tableBackground.color
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseCellId)
    }
}

// MARK: - TableView data source and delegate
extension ASCSharingOptionsAccessViewController {
    
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
        currentlyAccess = currentlyAccess != access ? access : nil
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        NSLocalizedString("Access by external link", comment: "")
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        NSLocalizedString("Документ будет доступен для просмотра неавторизированными пользователями, перешедшими по внещней ссылке.", comment: "")
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        heightForSectionHeader
    }
    
}
