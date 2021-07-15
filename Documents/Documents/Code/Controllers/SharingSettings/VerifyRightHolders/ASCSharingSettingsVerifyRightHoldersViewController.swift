//
//  ASCSharingSettingsVerifyRightHoldersViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 14.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingSettingsVerifyRightHoldersDisplayLogic: AnyObject {
    func displayData(viewModelType: ASCSharingSettingsVerifyRightHolders.Model.ViewModel.ViewModelData)
}

class ASCSharingSettingsVerifyRightHoldersViewController: ASCBaseTableViewController, ASCSharingSettingsVerifyRightHoldersDisplayLogic {
    
    var interactor: ASCSharingSettingsVerifyRightHoldersBusinessLogic?
    var router: (NSObjectProtocol & ASCSharingSettingsVerifyRightHoldersRoutingLogic & ASCSharingSettingsVerifyRightHoldersDataPassing)?
    
    private var verifyRightHoldersView: ASCSharingSettingsVerifyRightHoldersView?
    
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
    
    var usersModels: [ASCSharingRightHolderViewModel] = []
    var groupsModels: [ASCSharingRightHolderViewModel] = []
    
    private lazy var accessViewController = ASCSharingSettingsAccessViewController()
    private lazy var accessProvider: ASCSharingSettingsAccessProvider = ASCSharingSettingsAccessDefaultProvider()
    
    // MARK: Object lifecycle
    override init(style: UITableView.Style = .grouped) {
        super.init(style: style)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    private func setup() {
        let viewController        = self
        let interactor            = ASCSharingSettingsVerifyRightHoldersInteractor()
        let presenter             = ASCSharingSettingsVerifyRightHoldersPresenter()
        let router                = ASCSharingSettingsVerifyRightHoldersRouter()
        viewController.interactor = interactor
        viewController.router     = router
        interactor.presenter      = presenter
        presenter.viewController  = viewController
        router.viewController     = viewController
        router.dataStore          = interactor
    }
    
    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        load()
    }
    
    func reset() {
        verifyRightHoldersView?.reset()
    }
    
    func load() {
        verifyRightHoldersView = ASCSharingSettingsVerifyRightHoldersView(view: view, tableView: tableView)
        verifyRightHoldersView?.navigationController = navigationController
        verifyRightHoldersView?.navigationItem = navigationItem
        verifyRightHoldersView?.configure()
        
        tableView.register(ASCSwitchTableViewCell.self,
                           forCellReuseIdentifier: ASCSwitchTableViewCell.reuseId)
        tableView.register(ASCTextViewTableViewCell.self,
                           forCellReuseIdentifier: ASCTextViewTableViewCell.reuseId)
        tableView.register(ASCSharingRightHolderTableViewCell.self,
                           forCellReuseIdentifier: ASCSharingRightHolderTableViewCell.reuseId)
        
        loadShareItems()
        loadAccessProvider()

    }
    
    // MARK: - Requests
    func loadShareItems() {
        interactor?.makeRequest(requestType: .loadShareItems)
    }
    
    func loadAccessProvider() {
        interactor?.makeRequest(requestType: .loadAccessProvider)
    }
    
    func change(access: ASCShareAccess, forViewModel viewModel: ASCSharingRightHolderViewModel) {
        interactor?.makeRequest(requestType: .accessChange(.init(model: viewModel, newAccess: access)))
    }
    
    // MARK: - Display
    func displayData(viewModelType: ASCSharingSettingsVerifyRightHolders.Model.ViewModel.ViewModelData) {
        switch viewModelType {
        case .displayShareItems(viewMode: let viewModel):
            self.usersModels = viewModel.users
            self.groupsModels = viewModel.groups
            tableView.reloadData()
        case .displayAccessProvider(provider: let provider):
            self.accessProvider = provider
        case .displayApplyShareSettings(_):
            return
        case .displayAccessChange(viewModel: let viewModel):
            guard viewModel.errorMessage == nil else {
                log.error(viewModel.errorMessage!)
                return
            }
            if let index = usersModels.firstIndex(where: { $0.id == viewModel.model.id}) {
                usersModels[index] = viewModel.model
                tableView.reloadRows(at: [IndexPath(row: index, section: Section.users.rawValue)], with: .automatic)
            } else if let index = groupsModels.firstIndex(where: { $0.id == viewModel.model.id }) {
                groupsModels[index] = viewModel.model
                tableView.reloadRows(at: [IndexPath(row: index, section: Section.groups.rawValue)], with: .automatic)
            }
        }
    }
    
    // MARK: Routing
    func routeToAccessViewController(accessViewModel: ASCSharingSettingsAccessViewModel) {
        router?.routeToAccessViewController(viewModel: accessViewModel, segue: nil)
    }
}

// MARK: - Table view Data source & Delegate
extension ASCSharingSettingsVerifyRightHoldersViewController {
    
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = getSection(sectionRawValue: indexPath.section)
        
        switch section {
        case .notify: return
        case .users, .groups:
            let rightHolderViewModel = section == .users
                ? usersModels[indexPath.row]
                : groupsModels[indexPath.row]
            guard rightHolderViewModel.access?.accessEditable == true else { return }
            let accessViewModel = ASCSharingSettingsAccessViewModel(
                title: rightHolderViewModel.name,
                currentlyAccess: rightHolderViewModel.access?.entityAccess ?? .read,
                accessProvider: accessProvider,
                largeTitleDisplayMode: .automatic
            ) { [weak self] access in
                self?.change(access: access, forViewModel: rightHolderViewModel)
            }
            
            routeToAccessViewController(accessViewModel: accessViewModel)
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
extension ASCSharingSettingsVerifyRightHoldersViewController {
    
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
