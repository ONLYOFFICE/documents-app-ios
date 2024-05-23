//
//  ASCSharingInviteRightHoldersViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingInviteRightHoldersViewController: UIViewController, ASCSharingAddRightHoldersDisplayLogic {
    var interactor: ASCSharingAddRightHoldersBusinessLogic?
    var router: (NSObjectProtocol & ASCSharingAddRightHoldersRoutingLogic & ASCSharingAddRightHoldersDataPassing)?
    var dataStore: ASCSharingAddRightHoldersRAMDataStore?
    weak var sourceViewController: UIViewController? {
        didSet {
            dataStore?.doneCompletion = { [weak sourceViewController] in
                guard let sourceViewController = sourceViewController else { return }
                let message = NSLocalizedString("Link with the invitation has been sent to the mail", comment: "")
                let controller = UIAlertController(title: "", message: message, preferredStyle: .alert).okable()
                sourceViewController.present(controller, animated: true)
            }
        }
    }

    var sharingAddRightHoldersView: ASCSharingAddRightHoldersView?
    var defaultSelectedTable: RightHoldersTableType = .users

    var usersCurrentlyLoading = false {
        didSet {
            if usersCurrentlyLoading {
                sharingAddRightHoldersView?.runUsersLoadingAnimation()
            } else {
                sharingAddRightHoldersView?.stopUsersLoadingAnimation()
            }
        }
    }

    var groupsCurrentlyLoading = false {
        didSet {
            if groupsCurrentlyLoading {
                sharingAddRightHoldersView?.runGroupsLoadingAnimation()
            } else {
                sharingAddRightHoldersView?.stopGroupsLoadingAnimation()
            }
        }
    }

    lazy var defaultAccess: ASCShareAccess = {
        let accessList = accessProvider.get()
        guard accessList.contains(.read) else {
            return accessList.first ?? .read
        }
        return .read
    }()

    var accessProvider: ASCSharingSettingsAccessProvider = ASCSharingSettingsAccessDefaultProvider() {
        didSet {
            sharingAddRightHoldersView?.updateToolbars()
        }
    }

    lazy var selectedAccess: ASCShareAccess = self.defaultAccess
    var countOfSelectedRows: Int {
        (usersModels + groupsModels).reduce(0) { result, selectedModel in
            guard selectedModel.isSelected else { return result }
            return result + 1
        }
    }

    private var isSearchBarEmpty: Bool {
        guard let text = sharingAddRightHoldersView?.searchController.searchBar.text else {
            return false
        }
        return text.isEmpty
    }

    private var isSelectionRightHoldersChanged: Bool {
        guard let dataStore = router?.dataStore else { return false }

        return !dataStore.itemsForSharingAdd.isEmpty || !dataStore.itemsForSharingRemove.isEmpty
    }

    private lazy var usersTableViewDataSourceAndDelegate = ASCSharingInviteRightHoldersTableViewDataSourceAndDelegate<ASCSharingRightHolderTableViewCell>(models: self.usersModels)
    private lazy var groupsTableViewDataSourceAndDelegate = ASCSharingInviteRightHoldersTableViewDataSourceAndDelegate<ASCSharingRightHolderTableViewCell>(models: self.groupsModels)

    private lazy var searchResultsTableViewDataSourceAndDelegate: ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate = {
        guard let usersTableView = sharingAddRightHoldersView?.usersTableView,
              let groupsTableView = sharingAddRightHoldersView?.groupsTableView
        else {
            return ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate(tables: [:])
        }
        return ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate(tables: [.users: usersTableView, .groups: groupsTableView])
    }()

    private var usersModels: [(model: ASCSharingRightHolderViewModel, isSelected: IsSelected)] = []
    private var groupsModels: [(model: ASCSharingRightHolderViewModel, isSelected: IsSelected)] = []

    private lazy var onCellTapped: (ASCSharingRightHolderViewModel, IsSelected) -> Void = { [weak self] model, isSelected in
        guard let self = self else { return }
        self.selectedRow(model: model, isSelected: isSelected)
    }

    // MARK: Object lifecycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: Setup

    private func setup() {
        let viewController = self
        let interactor = ASCSharingAddRightHoldersInteractor(apiWorker: ASCShareSettingsAPIWorkerFactory().get(by: ASCPortalTypeDefinderByCurrentConnection().definePortalType()),
                                                             networkingRequestManager: OnlyofficeApiClient.shared)
        let presenter = ASCSharingAddRightHoldersPresenter()
        let router = ASCSharingAddRightHoldersRouter()
        let dataStore = ASCSharingAddRightHoldersRAMDataStore()
        viewController.interactor = interactor
        viewController.router = router
        viewController.dataStore = dataStore
        interactor.presenter = presenter
        interactor.dataStore = dataStore
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = dataStore
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        sharingAddRightHoldersView = ASCSharingAddRightHoldersView(
            view: view,
            navigationItem: navigationItem,
            navigationController: navigationController,
            searchControllerDelegate: self,
            searchResultsUpdating: self,
            searchBarDelegate: self,
            showsScopeBar: true
        )
        sharingAddRightHoldersView?.viewController = self
        sharingAddRightHoldersView?.delegate = self
        sharingAddRightHoldersView?.load()

        usersTableViewDataSourceAndDelegate.onCellTapped = onCellTapped
        groupsTableViewDataSourceAndDelegate.onCellTapped = onCellTapped

        sharingAddRightHoldersView?.usersTableView.dataSource = usersTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.usersTableView.delegate = usersTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.groupsTableView.dataSource = groupsTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.groupsTableView.delegate = groupsTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.searchResultsTable.dataSource = searchResultsTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.searchResultsTable.delegate = searchResultsTableViewDataSourceAndDelegate

        sharingAddRightHoldersView?.usersTableView.register(usersTableViewDataSourceAndDelegate.type, forCellReuseIdentifier: usersTableViewDataSourceAndDelegate.type.reuseId)
        sharingAddRightHoldersView?.groupsTableView.register(groupsTableViewDataSourceAndDelegate.type, forCellReuseIdentifier: groupsTableViewDataSourceAndDelegate.type.reuseId)

        sharingAddRightHoldersView?.showTable(tableType: .users)

        usersTableViewDataSourceAndDelegate.inviteCellClousure = { [weak self] in
            self?.showSureClearSelectionAlertIfNeededAndGoToInviteVC()
        }

        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UIDevice.pad || !(sharingAddRightHoldersView?.searchController.isActive ?? false) {
            if let keyboardFrame = sharingAddRightHoldersView?.dispalayingKeyboardFrame {
                sharingAddRightHoldersView?.changeModalHeightIfNeeded(keyboardSize: keyboardFrame)
            }
            navigationController?.isToolbarHidden = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sharingAddRightHoldersView?.saveCurrentPreferredSizeAsDefault()
        if UIDevice.pad || !(sharingAddRightHoldersView?.searchController.isActive ?? false) {
            navigationController?.isToolbarHidden = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if UIDevice.pad {
            sharingAddRightHoldersView?.resetModalSize()
            sharingAddRightHoldersView?.reloadEmptyViewIfNeeded()
        }
        navigationController?.isToolbarHidden = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.isToolbarHidden = true
        if UIDevice.pad {
            sharingAddRightHoldersView?.resetModalSize()
        }
    }

    func reset() {
        usersCurrentlyLoading = false
        groupsCurrentlyLoading = false
        selectedAccess = defaultAccess
        usersModels = []
        groupsModels = []
        usersTableViewDataSourceAndDelegate.set(models: [])
        groupsTableViewDataSourceAndDelegate.set(models: [])
        usersTableViewDataSourceAndDelegate.inviteSectionEnabled = false
        groupsTableViewDataSourceAndDelegate.inviteSectionEnabled = true

        updateSelectDeleselectAllBarBtn()
        sharingAddRightHoldersView?.reset()

        dataStore?.clear()
    }

    private func getSelectedTableView() -> UITableView {
        let type = getSelectedTableType()
        return sharingAddRightHoldersView?.getTableView(byRightHoldersTableType: type) ?? UITableView()
    }

    private func getSelectedTableType() -> RightHoldersTableType {
        guard let sharingAddRightHoldersView = sharingAddRightHoldersView, let tableType = RightHoldersTableType(rawValue: sharingAddRightHoldersView.searchController.searchBar.selectedScopeButtonIndex) else {
            let segmentedControlIndex = sharingAddRightHoldersView?.searchController.searchBar.selectedScopeButtonIndex ?? -1
            fatalError("Couldn't find a table type for segment control index: \(segmentedControlIndex)")
        }
        return tableType
    }

    /// when the screen is reused
    func start() {
        sharingAddRightHoldersView?.navigationItem = navigationItem
        sharingAddRightHoldersView?.navigationController = navigationController
        sharingAddRightHoldersView?.configureNavigationBar()
        sharingAddRightHoldersView?.configureToolBar()
        loadData()
    }

    // MARK: - Requests

    func loadData() {
        if !usersCurrentlyLoading {
            usersCurrentlyLoading = true
            interactor?.makeRequest(requestType: .loadUsers(preloadRightHolders: true, hideUsersWhoHasRights: true, showOnlyAdmins: false))
        }

        if !groupsCurrentlyLoading {
            groupsCurrentlyLoading = true
            interactor?.makeRequest(requestType: .loadGroups)
        }
    }

    func selectedRow(model: ASCSharingRightHolderViewModel, isSelected: IsSelected) {
        if isSelected {
            interactor?.makeRequest(requestType: .selectViewModel(.init(selectedViewModel: model, access: getCurrentAccess())))
        } else {
            interactor?.makeRequest(requestType: .deselectViewModel(.init(deselectedViewModel: model)))
        }
    }

    // MARK: - Display logic

    func displayData(viewModelType: ASCSharingAddRightHolders.Model.ViewModel.ViewModelData) {
        switch viewModelType {
        case let .displayUsers(viewModel: viewModel):
            usersModels = viewModel.users
            usersTableViewDataSourceAndDelegate.set(models: viewModel.users)
            sharingAddRightHoldersView?.usersTableView.reloadData()
            usersCurrentlyLoading = false
        case let .displayGroups(viewModel: viewModel):
            groupsModels = viewModel.groups
            groupsTableViewDataSourceAndDelegate.set(models: groupsModels)
            sharingAddRightHoldersView?.groupsTableView.reloadData()
            groupsCurrentlyLoading = false
        case let .displaySelected(viewModel: viewModel):
            switch viewModel.type {
            case .users:
                if let index = usersModels.firstIndex(where: { $0.0.id == viewModel.selectedModel.id }) {
                    usersModels[index].1 = viewModel.isSelect
                }
            case .groups:
                if let index = groupsModels.firstIndex(where: { $0.0.id == viewModel.selectedModel.id }) {
                    groupsModels[index].1 = viewModel.isSelect
                }
            }
        }

        updateNextBarBtnIfNeeded()
        sharingAddRightHoldersView?.updateTitle(withSelectedCount: countOfSelectedRows)
        if !usersCurrentlyLoading, !groupsCurrentlyLoading {
            updateSelectDeleselectAllBarBtn()
        }
    }

    func updateSelectDeleselectAllBarBtn() {
        if countOfSelectedRows > 0, countOfSelectedRows == usersModels.count + groupsModels.count {
            sharingAddRightHoldersView?.showDeselectBarBtn()
        } else {
            sharingAddRightHoldersView?.showSelectBarBtn()
        }
    }

    func updateNextBarBtnIfNeeded() {
        if sharingAddRightHoldersView?.isNextBarBtnEnabled != isSelectionRightHoldersChanged {
            sharingAddRightHoldersView?.isNextBarBtnEnabled.toggle()
        }
    }

    // MARK: Routing

    private func routeToVerifyRightHolders() {
        router?.routeToVerifyRightHoldersViewController(segue: nil, clearSharedInfoItems: true)
    }
}

// MARK: - View Delegate

extension ASCSharingInviteRightHoldersViewController: ASCSharingAddRightHoldersViewDelegate {
    func getAccessList() -> ([ASCShareAccess]) {
        return accessProvider.get()
    }

    func getCurrentAccess() -> ASCShareAccess {
        return selectedAccess
    }

    @available(iOS 14.0, *)
    func onAccessMenuSelectAction(action: UIAction, shareAccessRaw: Int) {
        onAccessSheetSelectAction(shareAccessRaw: shareAccessRaw)
    }

    func onAccessSheetSelectAction(shareAccessRaw: Int) {
        guard let access = ASCShareAccess(rawValue: shareAccessRaw) else { return }
        interactor?.makeRequest(requestType: .changeAccessForSelected(access))
        selectedAccess = access
    }

    func onUpdateToolbarItems(_ items: [UIBarButtonItem]?) {
        toolbarItems = items
    }

    func present(sheetAccessController: UIViewController) {
        present(sheetAccessController, animated: true, completion: nil)
    }

    func onNextButtonTapped() {
        navigationController?.isToolbarHidden = true
        routeToVerifyRightHolders()
    }

    func onSelectAllButtonTapped() {
        guard let sharingAddRightHoldersView = sharingAddRightHoldersView else {
            return
        }

        forEachRow(in: sharingAddRightHoldersView.usersTableView, applyAction: selectAction(in:by:))
        forEachRow(in: sharingAddRightHoldersView.groupsTableView, applyAction: selectAction(in:by:))
    }

    func onDeselectAllButtonTapped() {
        guard let sharingAddRightHoldersView = sharingAddRightHoldersView else {
            return
        }

        forEachRow(in: sharingAddRightHoldersView.usersTableView, applyAction: deselectAction(in:by:))
        forEachRow(in: sharingAddRightHoldersView.groupsTableView, applyAction: deselectAction(in:by:))
    }

    func onDismissButtonTapped() {
        navigationController?.dismiss(animated: true)
    }

    private func forEachRow(in tableView: UITableView, applyAction action: (UITableView, IndexPath) -> Void) {
        for section in 0 ..< tableView.numberOfSections {
            for row in 0 ..< tableView.numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                action(tableView, indexPath)
            }
        }
    }

    private func selectAction(in tableView: UITableView, by indexPath: IndexPath) {
        _ = tableView.delegate?.tableView?(tableView, willSelectRowAt: indexPath)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }

    private func deselectAction(in tableView: UITableView, by indexPath: IndexPath) {
        _ = tableView.delegate?.tableView?(tableView, willDeselectRowAt: indexPath)
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.delegate?.tableView?(tableView, didDeselectRowAt: indexPath)
    }
}

// MARK: - UI Search results updating

extension ASCSharingInviteRightHoldersViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }

        guard !searchText.isEmpty else {
            groupsTableViewDataSourceAndDelegate.set(models: groupsModels)
            usersTableViewDataSourceAndDelegate.set(models: usersModels)
            usersTableViewDataSourceAndDelegate.inviteSectionEnabled = false
            groupsTableViewDataSourceAndDelegate.inviteSectionEnabled = true
            sharingAddRightHoldersView?.showEmptyView(false)
            sharingAddRightHoldersView?.groupsTableView.reloadData()
            sharingAddRightHoldersView?.usersTableView.reloadData()
            sharingAddRightHoldersView?.searchResultsTable.reloadData()
            return
        }

        let foundGroupsModels = groupsModels.filter { $0.0.name.lowercased().contains(searchText.lowercased()) }
        let foundUsersModels = usersModels.filter { $0.0.name.lowercased().contains(searchText.lowercased()) }

        groupsTableViewDataSourceAndDelegate.set(models: foundGroupsModels)
        usersTableViewDataSourceAndDelegate.set(models: foundUsersModels)
        usersTableViewDataSourceAndDelegate.inviteSectionEnabled = false
        groupsTableViewDataSourceAndDelegate.inviteSectionEnabled = false

        sharingAddRightHoldersView?.groupsTableView.reloadData()
        sharingAddRightHoldersView?.usersTableView.reloadData()

        if sharingAddRightHoldersView?.searchResultsTable.superview == nil {
            getSelectedTableView().removeFromSuperview()
            sharingAddRightHoldersView?.removeDarkenFromScreen()
            sharingAddRightHoldersView?.showSearchResultTable()
        }
        sharingAddRightHoldersView?.searchResultsTable.reloadData()

        if foundUsersModels.isEmpty, foundGroupsModels.isEmpty {
            sharingAddRightHoldersView?.showEmptyView(true)
        } else {
            sharingAddRightHoldersView?.showEmptyView(false)
        }
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        if UIDevice.phone {
            navigationController?.isToolbarHidden = true
        }
        DispatchQueue.main.async {
            self.sharingAddRightHoldersView?.darkenScreen()
        }
        sharingAddRightHoldersView?.hideTablesSegmentedControl()
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        if UIDevice.phone {
            navigationController?.isToolbarHidden = false
        }
        sharingAddRightHoldersView?.removeDarkenFromScreen()

        groupsTableViewDataSourceAndDelegate.set(models: groupsModels)
        usersTableViewDataSourceAndDelegate.set(models: usersModels)
        usersTableViewDataSourceAndDelegate.inviteSectionEnabled = false
        groupsTableViewDataSourceAndDelegate.inviteSectionEnabled = true

        sharingAddRightHoldersView?.groupsTableView.reloadData()
        sharingAddRightHoldersView?.usersTableView.reloadData()

        if getSelectedTableView().superview == nil {
            sharingAddRightHoldersView?.showTable(tableType: getSelectedTableType())
        }

        sharingAddRightHoldersView?.showTablesSegmentedControl()
        sharingAddRightHoldersView?.searchResultsTable.removeFromSuperview()
        sharingAddRightHoldersView?.showEmptyView(false)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if UIDevice.phone {
            navigationController?.isToolbarHidden = false
        }
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let tableType = RightHoldersTableType(rawValue: selectedScope) else { return }
        sharingAddRightHoldersView?.showTable(tableType: tableType)
    }
}

// MARK: - Navigation helper

extension ASCSharingInviteRightHoldersViewController {
    func showInviteByEmailViewController() {
        guard let entity = dataStore?.entity else { return }
        let apiWorker = ASCShareSettingsAPIWorkerFactory().get(by: ASCPortalTypeDefinderByCurrentConnection().definePortalType())
        let viewModel = InviteRigthHoldersByEmailsViewModelImp(entity: entity, currentAccess: selectedAccess, apiWorker: apiWorker, accessProvider: accessProvider) { [weak self] emails, access in
            guard let self = self else { return }
            self.dataStore?.sharedInfoItems = []
            self.dataStore?.itemsForSharingAdd = []
            self.dataStore?.itemsForSharingRemove = []
            for email in emails {
                self.dataStore?.add(shareInfo: .init(access: access, email: email))
            }
            self.routeToVerifyRightHolders()
        }
        let inviteVC = InviteRigthHoldersByEmailsViewController(viewModel: viewModel)
        inviteVC.view.frame = view.bounds
        navigationController?.pushViewController(inviteVC, animated: true)
    }
}

// MARK: - Alert helpers

extension ASCSharingInviteRightHoldersViewController {
    func showSureClearSelectionAlertIfNeededAndGoToInviteVC() {
        guard dataStore?.itemsForSharingAdd.isEmpty == false else {
            showInviteByEmailViewController()
            return
        }
        let title = NSLocalizedString("Clear selection?", comment: "")
        let message = NSLocalizedString("Selected users will not be invited to the room", comment: "")
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addOk { [unowned self] _ in
            showInviteByEmailViewController()
            dataStore?.itemsForSharingAdd = []
            dataStore?.itemsForSharingRemove = []
        }
        controller.addCancel()
        present(controller, animated: true)
    }
}
