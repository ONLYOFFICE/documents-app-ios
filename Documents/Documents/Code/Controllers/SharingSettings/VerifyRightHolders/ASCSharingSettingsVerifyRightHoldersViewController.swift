//
//  ASCSharingSettingsVerifyRightHoldersViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 14.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
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
    private var currentlyApplying: Bool = false
    private var hud: MBProgressHUD?

    // MARK: Object lifecycle

    override init(style: UITableView.Style = .grouped) {
        super.init(style: style)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup

    private func setup() {
        let viewController = self
        let interactor = ASCSharingSettingsVerifyRightHoldersInteractor(apiWorker: ASCShareSettingsAPIWorker())
        let presenter = ASCSharingSettingsVerifyRightHoldersPresenter()
        let router = ASCSharingSettingsVerifyRightHoldersRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        load()
    }

    func reset() {
        needToNotify = false
        verifyRightHoldersView?.reset()
    }

    func load() {
        title = NSLocalizedString("Sharing settings", comment: "")
        verifyRightHoldersView = ASCSharingSettingsVerifyRightHoldersView(view: view, tableView: tableView)
        verifyRightHoldersView?.navigationController = navigationController
        verifyRightHoldersView?.navigationItem = navigationItem
        verifyRightHoldersView?.delegate = self
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

    func delete(accessForRightHolderByIndexPath indexPath: IndexPath) {
        guard let viewModel = getViewModel(byIndexPath: indexPath) else { return }
        interactor?.makeRequest(requestType: .accessRemove(.init(model: viewModel, indexPath: indexPath)))
    }

    func apply() {
        if !currentlyApplying {
            currentlyApplying = true
            hud = MBProgressHUD.showTopMost()
            hud?.label.text = NSLocalizedString("Applying", comment: "Caption of the process")
            var notifyMessage: String?
            let notifyCellIndexPath = IndexPath(row: Section.Notify.message.rawValue, section: Section.notify.rawValue)
            if needToNotify, let cell = tableView.cellForRow(at: notifyCellIndexPath) as? ASCTextViewTableViewCell {
                notifyMessage = cell.getText()
            }
            interactor?.makeRequest(requestType: .applyShareSettings(.init(notify: needToNotify, notifyMessage: notifyMessage)))
        }
    }

    // MARK: - Display

    func displayData(viewModelType: ASCSharingSettingsVerifyRightHolders.Model.ViewModel.ViewModelData) {
        switch viewModelType {
        case let .displayShareItems(viewMode: viewModel):
            usersModels = viewModel.users
            groupsModels = viewModel.groups
            tableView.reloadData()
        case let .displayAccessProvider(provider: provider):
            accessProvider = provider
        case let .displayApplyShareSettings(viewModel: viewModel):
            currentlyApplying = false
            if viewModel.error == nil {
                hud?.setSuccessState()
                let delay: TimeInterval = 0.65
                hud?.hide(animated: true, afterDelay: delay)
                hud = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.routeToParent()
                }
            } else if let errorMessage = viewModel.error {
                hud?.hide(animated: false)
                hud = nil
                UIAlertController.showError(in: self, message: errorMessage)
            }
        case let .displayAccessChange(viewModel: viewModel):
            guard viewModel.errorMessage == nil else {
                log.error(viewModel.errorMessage!)
                return
            }
            if let index = usersModels.firstIndex(where: { $0.id == viewModel.model.id }) {
                usersModels[index] = viewModel.model
                tableView.reloadRows(at: [IndexPath(row: index, section: Section.users.rawValue)], with: .automatic)
            } else if let index = groupsModels.firstIndex(where: { $0.id == viewModel.model.id }) {
                groupsModels[index] = viewModel.model
                tableView.reloadRows(at: [IndexPath(row: index, section: Section.groups.rawValue)], with: .automatic)
            }
        case let .displayAccessRemove(viewModel: viewModel):
            guard viewModel.errorMessage == nil else {
                log.error(viewModel.errorMessage!)
                return
            }
            let section = getSection(sectionRawValue: viewModel.indexPath.section)
            switch section {
            case .users: usersModels.remove(at: viewModel.indexPath.row)
            case .groups: groupsModels.remove(at: viewModel.indexPath.row)
            default: return
            }
            tableView.deleteRows(at: [viewModel.indexPath], with: .fade)
        }
    }

    // MARK: Routing

    func routeToAccessViewController(accessViewModel: ASCSharingSettingsAccessViewModel) {
        router?.routeToAccessViewController(viewModel: accessViewModel, segue: nil)
    }

    func routeToParent() {
        router?.routeToParentWithDoneCopmletion(segue: nil)
    }
}

// MARK: - View Delegate

extension ASCSharingSettingsVerifyRightHoldersViewController: ASCSharingSettingsVerifyRightHoldersViewDelegate {
    func onDoneBarBtnTapped() {
        apply()
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
                accessNoteProvider: ASCSharingSettingsAccessNotesProvidersFactory().get(accessType: .userOrGroup),
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
        let hasRows = self.tableView(tableView, numberOfRowsInSection: section) > 0
        return hasRows ? getSection(sectionRawValue: section).title() : nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let hasRows = self.tableView(tableView, numberOfRowsInSection: section) > 0
        let section = getSection(sectionRawValue: section)
        return hasRows ? section.heightForSectionHeader() : CGFloat.zero
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard canCellBeDeleted(indexPath: indexPath) else { return nil }

        return UISwipeActionsConfiguration(actions: [.init(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { action, view, completion in
            self.delete(accessForRightHolderByIndexPath: indexPath)
            completion(true)
        })])
    }

    // MARK: - Support table view methods

    private func canCellBeDeleted(indexPath: IndexPath) -> Bool {
        guard let viewModel = getViewModel(byIndexPath: indexPath) else {
            return false
        }
        return viewModel.access?.accessEditable ?? false
    }

    private func getViewModel(byIndexPath indexPath: IndexPath) -> ASCSharingRightHolderViewModel? {
        let section = getSection(sectionRawValue: indexPath.section)
        switch section {
        case .users, .groups:
            let rightHolderViewModel = section == .users
                ? usersModels[indexPath.row]
                : groupsModels[indexPath.row]
            return rightHolderViewModel
        default: return nil
        }
    }

    private func getCell<T: UITableViewCell & ASCReusedIdentifierProtocol>() -> T {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: T.reuseId) as? T else {
            fatalError("couldn't cast cell to \(T.self)")
        }
        return cell
    }

    private func getSection(sectionRawValue rawValue: Int) -> Section {
        guard let section = Section(rawValue: rawValue) else { fatalError("Couldn't find a section by index: \(rawValue)") }
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
