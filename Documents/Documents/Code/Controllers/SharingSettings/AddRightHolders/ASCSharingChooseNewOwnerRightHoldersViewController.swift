//
//  ASCSharingChooseNewOwnerRightHoldersViewController.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 02.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import UIKit

class ASCSharingChooseNewOwnerRightHoldersViewController: UIViewController, ASCSharingAddRightHoldersDisplayLogic {
    var interactor: ASCSharingAddRightHoldersBusinessLogic?
    var dataStore: ASCSharingAddRightHoldersRAMDataStore?

    var sharingChooseNewOwnerRightHoldersView: ASCSharingChooseNewOwnerRightHoldersView?
    var defaultSelectedTable: RightHoldersTableType = .users

    var usersCurrentlyLoading = false {
        didSet {
            if usersCurrentlyLoading {
                sharingChooseNewOwnerRightHoldersView?.runUsersLoadingAnimation()
            } else {
                sharingChooseNewOwnerRightHoldersView?.stopUsersLoadingAnimation()
            }
        }
    }

    private var isSearchBarEmpty: Bool {
        guard let text = sharingChooseNewOwnerRightHoldersView?.searchController.searchBar.text else {
            return false
        }
        return text.isEmpty
    }

    private lazy var usersTableViewDataSourceAndDelegate = ASCSharingChooseNewOwnerRightHoldersTableViewDataSourceAndDelegate<ASCSharingRightHolderTableViewCell>(models: self.usersModels)

    private lazy var searchResultsTableViewDataSourceAndDelegate: ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate = {
        guard let usersTableView = sharingChooseNewOwnerRightHoldersView?.usersTableView
        else {
            return ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate(tables: [:])
        }
        return ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate(tables: [.users: usersTableView])
    }()

    private lazy var onCellTapped: (ASCSharingRightHolderViewModel, IsSelected) -> Void = { [weak self] model, isSelected in
        guard let self = self else { return }
        self.selectRow(userId: model.id)
    }

    private var usersModels: [(model: ASCSharingRightHolderViewModel, isSelected: IsSelected)] = []

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

        sharingChooseNewOwnerRightHoldersView = ASCSharingChooseNewOwnerRightHoldersView(
            view: view,
            navigationItem: navigationItem,
            navigationController: navigationController,
            searchControllerDelegate: self,
            searchResultsUpdating: self,
            searchBarDelegate: self,
            showsScopeBar: false
        )
        sharingChooseNewOwnerRightHoldersView?.viewController = self
        sharingChooseNewOwnerRightHoldersView?.load()

        usersTableViewDataSourceAndDelegate.onCellTapped = onCellTapped

        sharingChooseNewOwnerRightHoldersView?.usersTableView.dataSource = usersTableViewDataSourceAndDelegate
        sharingChooseNewOwnerRightHoldersView?.usersTableView.delegate = usersTableViewDataSourceAndDelegate
        sharingChooseNewOwnerRightHoldersView?.searchResultsTable.dataSource = searchResultsTableViewDataSourceAndDelegate
        sharingChooseNewOwnerRightHoldersView?.searchResultsTable.delegate = searchResultsTableViewDataSourceAndDelegate

        sharingChooseNewOwnerRightHoldersView?.usersTableView.register(usersTableViewDataSourceAndDelegate.type, forCellReuseIdentifier: usersTableViewDataSourceAndDelegate.type.reuseId)

        sharingChooseNewOwnerRightHoldersView?.showTable(tableType: .users)

        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UIDevice.pad || !(sharingChooseNewOwnerRightHoldersView?.searchController.isActive ?? false) {
            if let keyboardFrame = sharingChooseNewOwnerRightHoldersView?.dispalayingKeyboardFrame {
                sharingChooseNewOwnerRightHoldersView?.changeModalHeightIfNeeded(keyboardSize: keyboardFrame)
            }
            navigationController?.isToolbarHidden = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sharingChooseNewOwnerRightHoldersView?.saveCurrentPreferredSizeAsDefault()
        if UIDevice.pad || !(sharingChooseNewOwnerRightHoldersView?.searchController.isActive ?? false) {
            navigationController?.isToolbarHidden = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if UIDevice.pad {
            sharingChooseNewOwnerRightHoldersView?.resetModalSize()
            sharingChooseNewOwnerRightHoldersView?.reloadEmptyViewIfNeeded()
        }
        navigationController?.isToolbarHidden = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.isToolbarHidden = true
        if UIDevice.pad {
            sharingChooseNewOwnerRightHoldersView?.resetModalSize()
        }
    }

    func reset() {
        usersCurrentlyLoading = false
        usersModels = []
        usersTableViewDataSourceAndDelegate.set(models: [])
        sharingChooseNewOwnerRightHoldersView?.reset()

        dataStore?.clear()
    }

    private func getSelectedTableView() -> UITableView {
        let type = getSelectedTableType()
        return sharingChooseNewOwnerRightHoldersView?.getTableView(byRightHoldersTableType: type) ?? UITableView()
    }

    private func getSelectedTableType() -> RightHoldersTableType {
        guard let sharingAddRightHoldersView = sharingChooseNewOwnerRightHoldersView, let tableType = RightHoldersTableType(rawValue: sharingAddRightHoldersView.searchController.searchBar.selectedScopeButtonIndex) else {
            let segmentedControlIndex = sharingChooseNewOwnerRightHoldersView?.searchController.searchBar.selectedScopeButtonIndex ?? -1
            fatalError("Couldn't find a table type for segment control index: \(segmentedControlIndex)")
        }
        return tableType
    }

    /// when the screen is reused
    func start() {
        sharingChooseNewOwnerRightHoldersView?.navigationItem = navigationItem
        sharingChooseNewOwnerRightHoldersView?.navigationController = navigationController
        sharingChooseNewOwnerRightHoldersView?.configureNavigationBar()
        loadData()
    }

    // MARK: - Requests

    func loadData() {
        if !usersCurrentlyLoading {
            usersCurrentlyLoading = true
            interactor?.makeRequest(requestType: .loadUsers(preloadRightHolders: true, hideUsersWhoHasRights: false))
        }
    }

    func selectRow(userId: String) {
        var hud: MBProgressHUD?
        hud?.label.text = NSLocalizedString("Leaving...", comment: "Caption of the process")

        interactor?.makeRequest(requestType: .changeOwner(userId) { status, result, error in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
            } else if status == .error {
                hud?.hide(animated: true)
                UIAlertController.showError(
                    in: self,
                    message: NSLocalizedString("Couldn't leave the room", comment: "")
                )
                self.dismiss(animated: true)
            } else if status == .end {
                hud?.setSuccessState()
                hud?.label.text = NSLocalizedString("You have left the room and appointed a new owner", comment: "")
                hud?.hide(animated: false, afterDelay: 1.3)
                self.dismiss(animated: true)
            }
        })
    }

    // MARK: - Display logic

    func displayData(viewModelType: ASCSharingAddRightHolders.Model.ViewModel.ViewModelData) {
        switch viewModelType {
        case let .displayUsers(viewModel: viewModel):
            usersModels = viewModel.users
            usersTableViewDataSourceAndDelegate.set(models: viewModel.users)
            sharingChooseNewOwnerRightHoldersView?.usersTableView.reloadData()
            usersCurrentlyLoading = false
        case .displayGroups:
            return
        case let .displaySelected(viewModel: viewModel):
            switch viewModel.type {
            case .users:
                if let index = usersModels.firstIndex(where: { $0.0.id == viewModel.selectedModel.id }) {
                    usersModels[index].1 = viewModel.isSelect
                }
            case .groups:
                return
            }
        }
    }
}

// MARK: - UI Search results updating

extension ASCSharingChooseNewOwnerRightHoldersViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }

        guard !searchText.isEmpty else {
            usersTableViewDataSourceAndDelegate.set(models: usersModels)
            sharingChooseNewOwnerRightHoldersView?.showEmptyView(false)
            sharingChooseNewOwnerRightHoldersView?.usersTableView.reloadData()
            sharingChooseNewOwnerRightHoldersView?.searchResultsTable.reloadData()
            return
        }

        let foundUsersModels = usersModels.filter { $0.0.name.lowercased().contains(searchText.lowercased()) }

        usersTableViewDataSourceAndDelegate.set(models: foundUsersModels)

        sharingChooseNewOwnerRightHoldersView?.usersTableView.reloadData()

        if sharingChooseNewOwnerRightHoldersView?.searchResultsTable.superview == nil {
            getSelectedTableView().removeFromSuperview()
            sharingChooseNewOwnerRightHoldersView?.removeDarkenFromScreen()
            sharingChooseNewOwnerRightHoldersView?.showSearchResultTable()
        }
        sharingChooseNewOwnerRightHoldersView?.searchResultsTable.reloadData()

        if foundUsersModels.isEmpty {
            sharingChooseNewOwnerRightHoldersView?.showEmptyView(true)
        } else {
            sharingChooseNewOwnerRightHoldersView?.showEmptyView(false)
        }
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        if UIDevice.phone {
            navigationController?.isToolbarHidden = true
        }
        DispatchQueue.main.async {
            self.sharingChooseNewOwnerRightHoldersView?.darkenScreen()
        }
        sharingChooseNewOwnerRightHoldersView?.hideTablesSegmentedControl()
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        if UIDevice.phone {
            navigationController?.isToolbarHidden = false
        }
        sharingChooseNewOwnerRightHoldersView?.removeDarkenFromScreen()

        usersTableViewDataSourceAndDelegate.set(models: usersModels)

        sharingChooseNewOwnerRightHoldersView?.usersTableView.reloadData()

        if getSelectedTableView().superview == nil {
            sharingChooseNewOwnerRightHoldersView?.showTable(tableType: getSelectedTableType())
        }

        sharingChooseNewOwnerRightHoldersView?.showTablesSegmentedControl()
        sharingChooseNewOwnerRightHoldersView?.searchResultsTable.removeFromSuperview()
        sharingChooseNewOwnerRightHoldersView?.showEmptyView(false)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if UIDevice.phone {
            navigationController?.isToolbarHidden = false
        }
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let tableType = RightHoldersTableType(rawValue: selectedScope) else { return }
        sharingChooseNewOwnerRightHoldersView?.showTable(tableType: tableType)
    }
}
