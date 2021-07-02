//
//  ASCSharingSettingsVerifyRightHolders.swift
//  Documents
//
//  Created by Pavel Chernyshev on 24.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingSettingsVerifyRightHolders: ASCBaseTableViewController {
    
    private var needToNotify = false {
        didSet {
            tableView.reloadSections(IndexSet(arrayLiteral: Section.notify.rawValue), with: .automatic)
        }
    }
    
    private lazy var notifySwitchHandler: (Bool) -> Void = { [weak self] activating in
        guard let self = self else {
            return
        }
        self.needToNotify = activating
    }
    
    private var usersModels = [
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Pavel Chernyshev Pavel Chernyshev Pavel Chernyshev Pavel Chernyshev Pavel Chernyshev", department: "manager", isOwner: true, access: .init(documetAccess: .full, accessEditable: false)),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Dimitry Dmittrov", department: "manager", isOwner: false, access: .init(documetAccess: .read, accessEditable: true)),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Admins",  department: "manager", isOwner: true, access: .init(documetAccess: .review, accessEditable: true)),
    ]
    
    var groupsModels = [
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Admins", access: .init(documetAccess: .read, accessEditable: true)),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Disigners", access: .init(documetAccess: .read, accessEditable: true))
    ]
    
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
        navigationController?.navigationBar.backItem?.backButtonTitle = NSLocalizedString("Back", comment: "")
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = NSLocalizedString("Done", comment: "")
        navigationController?.navigationBar.topItem?.title = NSLocalizedString("Sharing settings", comment: "")
    }
    
    private func configureTableView() {
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = Asset.Colors.tableBackground.color
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = 0
        
        tableView.tableHeaderView = UIView()
        
        tableView.register(ASCSwitchTableViewCell.self,
                           forCellReuseIdentifier: ASCSwitchTableViewCell.reuseId)
        tableView.register(ASCTextViewTableViewCell.self,
                           forCellReuseIdentifier: ASCTextViewTableViewCell.reuseId)
        tableView.register(ASCSharingRightHolderTableViewCell.self,
                           forCellReuseIdentifier: ASCSharingRightHolderTableViewCell.reuseId)
    }
    
}

// MARK: - Table view Data source & Delegate
extension ASCSharingSettingsVerifyRightHolders {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = getSection(sectionRawValue: section)
        switch section {
        case .notify:
            return needToNotify ? 2 : 1
        case .users:
            return usersModels.count
        case .groups:
            return groupsModels.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = getSection(sectionRawValue: indexPath.section)

        
        switch section {
        case .notify:
            guard let notifyRow = Section.Notify(rawValue: indexPath.row) else {
                fatalError("Couldn't find ExternalLinkRow for index \(indexPath.row)")
            }
            
            switch notifyRow {
            case .switcher:
                let cell: ASCSwitchTableViewCell = getCell()
                cell.viewModel = ASCSwitchRowViewModel(title: notifyRow.title(), isActive: needToNotify, toggleHandler: notifySwitchHandler)
                return cell
            case .message:
                let cell: ASCTextViewTableViewCell = getCell()
                cell.viewModel = .init(placeholder: notifyRow.title())
                return cell
            }
        case .users:
             let cell: ASCSharingRightHolderTableViewCell = getCell()
             cell.viewModel = usersModels[indexPath.row]
             return cell
         case .groups:
            let cell: ASCSharingRightHolderTableViewCell = getCell()
            cell.viewModel = groupsModels[indexPath.row]
            return cell
        }
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = getSection(sectionRawValue: indexPath.section)
        guard section != .notify else {
            guard let notify = Section.Notify(rawValue: indexPath.row) else {
                fatalError("couldn't get Section Notify by index \(indexPath.row)")
            }
            return section.heightForRow(notify)
        }
        return section.heightForRow()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return getSection(sectionRawValue: section).title()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = getSection(sectionRawValue: section)
        return section.heightForSectionHeader()
    }
    
    private func getCell<T: UITableViewCell & ASCReusedIdentifierProtocol>() -> T {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: T.reuseId) as? T else {
            fatalError("couldn't cast cell to \(T.self)")
        }
        return cell
    }
    
    private func getSection(sectionRawValue rawValue: Int) -> Section {
        guard let section = Section(rawValue: rawValue) else { fatalError("Couldn't find a section by index: \(rawValue)")}
        return section
    }
}

// MARK: - Sections
extension ASCSharingSettingsVerifyRightHolders {
    
    enum Section: Int, CaseIterable {
        case notify
        case users
        case groups
        
        func title() -> String? {
            switch self {
            case .notify: return nil
            case .users: return NSLocalizedString("Users", comment: "")
            case .groups: return NSLocalizedString("Groups", comment: "")
            }
        }
        
        func heightForRow(_ notyfy: Notify? = nil) -> CGFloat {
            switch self {
            case .notify:
                guard let notify = notyfy else { return 44 }
                switch notify {
                case .switcher: return 44
                case .message: return 88
                }
            case .users, .groups: return 60
            }
        }
        
        func heightForSectionHeader() -> CGFloat {
            switch self {
            case .notify: return CGFloat.leastNonzeroMagnitude
            case .users: return 38
            case .groups: return 38
            }
        }
        
        enum Notify: Int, CaseIterable {
            case switcher
            case message
            
            func title() -> String {
                switch self {
                case .switcher: return NSLocalizedString("Notify by Email", comment: "Sharing settings switcher")
                case .message: return NSLocalizedString("Add message", comment: "Sharing settings add notification message")
                }
            }
        }
    }
    
}
