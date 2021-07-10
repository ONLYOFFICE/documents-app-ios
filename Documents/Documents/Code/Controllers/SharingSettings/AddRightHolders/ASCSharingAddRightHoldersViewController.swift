//
//  ASCSharingAddRightHoldersViewController.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingAddRightHoldersDisplayLogic: AnyObject {
    func displayData(viewModelType: ASCSharingAddRightHolders.Model.ViewModel.ViewModelData)
}

class ASCSharingAddRightHoldersViewController: UIViewController, ASCSharingAddRightHoldersDisplayLogic {
    
    var interactor: ASCSharingAddRightHoldersBusinessLogic?
    var router: (NSObjectProtocol & ASCSharingAddRightHoldersRoutingLogic)?
    
    var sharingAddRightHoldersView: ASCSharingAddRightHoldersView?
    var defaultSelectedTable: RightHoldersTableType = .users
    
    let defaultAccess: ASCShareAccess = .read
    lazy var selectedAccess: ASCShareAccess = self.defaultAccess
    
    private var isSearchBarEmpty: Bool {
        guard let text = sharingAddRightHoldersView?.searchController.searchBar.text else {
            return false
        }
        return text.isEmpty
    }
    
    private lazy var usersTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<ASCSharingRightHolderTableViewCell>(models: self.usersModels)
    private lazy var groupsTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<ASCSharingRightHolderTableViewCell>(models: self.groupsModels)
    
    private lazy var searchResultsTableViewDataSourceAndDelegate: ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate = {
        guard let usersTableView = sharingAddRightHoldersView?.usersTableView,
              let groupsTableView = sharingAddRightHoldersView?.groupsTableView
        else {
            return ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate(tables: [:])
        }
        return ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate(tables: [ .users: usersTableView, .groups: groupsTableView])
    }()
    
    var usersModels: [ASCSharingRightHolderViewModel] = [
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Abel – Abe, Abie;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Abner – Ab, Abbie;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Abraham, Abram – Abe, Abie, Bram;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Adam – Ad, Addie, Addy, Ade;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Benjamin – Ben, Bennie, Benny, Benjy Benjie;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Bennet, Bennett – Ben, Bennie, Benny;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Bernard, Barnard – Bernie, Berney, Barney, Barnie", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Christopher Kit, Kester, Kristof, Toph,", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Clarence – Clare, Clair;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Clare, Clair;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Clark, Clarke;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Claude, Claud;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Donald – Don, Donnie, Donny", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Donovan – Don, Donnie, Donny;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Dorian;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Dougls, Douglass – Doug;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Doyle;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Drew (see Andrew);", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Elliot, Elliott – El;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Ellis – El;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Elmer – El;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Elton, Alton – El, Al;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Elvin, Elwin, Elwyn – El, Vin, Vinny, Win;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Elvis – El;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Herman – Manny, Mannie;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Hilary, Hillary – Hill, Hillie, Hilly;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Homer;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Horace, Horatio;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Howard – Howie;", rightHolderType: .user),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Hubert – Hugh, Bert, Bertie", rightHolderType: .user),
    ]
    
    var groupsModels: [ASCSharingRightHolderViewModel] = [
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Admins"),
        ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Disigners")
    ]
    
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
        let viewController        = self
        let interactor            = ASCSharingAddRightHoldersInteractor()
        let presenter             = ASCSharingAddRightHoldersPresenter()
        let router                = ASCSharingAddRightHoldersRouter()
        viewController.interactor = interactor
        viewController.router     = router
        interactor.presenter      = presenter
        presenter.viewController  = viewController
        router.viewController     = viewController
    }
    
    // MARK: Routing
    
    
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharingAddRightHoldersView = ASCSharingAddRightHoldersView(
            view: view,
            navigationItem: navigationItem,
            navigationController: navigationController,
            searchControllerDelegate: self,
            searchResultsUpdating: self)
        sharingAddRightHoldersView?.delegate = self
        sharingAddRightHoldersView?.load()
        
        sharingAddRightHoldersView?.usersTableView.dataSource = usersTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.usersTableView.delegate = usersTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.groupsTableView.dataSource = groupsTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.groupsTableView.delegate = groupsTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.searchResultsTable.dataSource = searchResultsTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.searchResultsTable.delegate = searchResultsTableViewDataSourceAndDelegate
        
        sharingAddRightHoldersView?.usersTableView.register(usersTableViewDataSourceAndDelegate.type, forCellReuseIdentifier: usersTableViewDataSourceAndDelegate.type.reuseId)
        sharingAddRightHoldersView?.groupsTableView.register(groupsTableViewDataSourceAndDelegate.type, forCellReuseIdentifier: groupsTableViewDataSourceAndDelegate.type.reuseId)
        
        sharingAddRightHoldersView?.showTable(tableType: defaultSelectedTable)
        
        interactor?.makeRequest(requestType: .loadUsers)
    }
    
    private func getSelectedTableView() -> UITableView {
        let type = getSelectedTableType()
        return sharingAddRightHoldersView?.getTableView(byRightHoldersTableType: type) ?? UITableView()
    }
    
    private func getSelectedTableType() -> RightHoldersTableType {
        guard let sharingAddRightHoldersView = sharingAddRightHoldersView, let tableType = RightHoldersTableType(rawValue: sharingAddRightHoldersView.tablesSegmentedControl.selectedSegmentIndex) else {
            let segmentedControlIndex = sharingAddRightHoldersView?.tablesSegmentedControl.selectedSegmentIndex ?? -1
            fatalError("Couldn't find a table type for segment control index: \(segmentedControlIndex)")
        }
        return tableType
    }
    
    func displayData(viewModelType: ASCSharingAddRightHolders.Model.ViewModel.ViewModelData) {
        switch viewModelType {
        case .displayUsers(viewModel: let viewModel):
            self.usersModels = viewModel.users
            usersTableViewDataSourceAndDelegate.setModels(models: viewModel.users)
            sharingAddRightHoldersView?.usersTableView.reloadData()
        case .displayGroups(_):
            return
        }
    }
    
}

// MARK: - View Delegate
extension ASCSharingAddRightHoldersViewController: ASCSharingAddRightHoldersViewDelegate {
    func getAccessList() -> ([ASCShareAccess]) {
        return ASCSharingSettingsAccessDefaultProvider().get() // MARK: - TODO
    }
    
    func getCurrentAccess() -> ASCShareAccess {
        return selectedAccess
    }
    
    func tablesSegmentedControlDidChanged() {
        let tableType = getSelectedTableType()
        sharingAddRightHoldersView?.showTable(tableType: tableType)
    }
    
    @available(iOS 14.0, *)
    func onAccessMenuSelectAction(action: UIAction, shareAccessRaw: Int) {
        onAccessSheetSelectAction(shareAccessRaw: shareAccessRaw)
    }
    
    func onAccessSheetSelectAction(shareAccessRaw: Int) {
        guard let access = ASCShareAccess(rawValue: shareAccessRaw) else { return }
        self.selectedAccess = access
    }
    
    func onUpdateToolbarItems(_ items: [UIBarButtonItem]?) {
        toolbarItems = items
    }
    
    func present(sheetAccessController: UIViewController) {
        present(sheetAccessController, animated: true, completion: nil)
    }
}

// MARK: - UI Search results updating
extension ASCSharingAddRightHoldersViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        
        guard !searchText.isEmpty else {
            groupsTableViewDataSourceAndDelegate.setModels(models: groupsModels)
            sharingAddRightHoldersView?.groupsTableView.reloadData()
            usersTableViewDataSourceAndDelegate.setModels(models: usersModels)
            sharingAddRightHoldersView?.usersTableView.reloadData()
            sharingAddRightHoldersView?.searchResultsTable.reloadData()
            return
        }
        
        groupsTableViewDataSourceAndDelegate.setModels(models: groupsModels.filter({ $0.name.lowercased().contains(searchText.lowercased()) }))
        sharingAddRightHoldersView?.groupsTableView.reloadData()
        usersTableViewDataSourceAndDelegate.setModels(models: usersModels.filter({ $0.name.lowercased().contains(searchText.lowercased()) }))
        sharingAddRightHoldersView?.usersTableView.reloadData()
        
        if sharingAddRightHoldersView?.searchResultsTable.superview == nil {
            getSelectedTableView().removeFromSuperview()
            sharingAddRightHoldersView?.removeDarkenFromScreen()
            sharingAddRightHoldersView?.showSearchResultTable()
        }
        sharingAddRightHoldersView?.searchResultsTable.reloadData()
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            self.sharingAddRightHoldersView?.darkenScreen()
        }
        sharingAddRightHoldersView?.hideTablesSegmentedControl()
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        sharingAddRightHoldersView?.removeDarkenFromScreen()
        
        groupsTableViewDataSourceAndDelegate.setModels(models: groupsModels)
        usersTableViewDataSourceAndDelegate.setModels(models: usersModels)
        
        if getSelectedTableView().superview == nil {
            sharingAddRightHoldersView?.showTable(tableType: self.getSelectedTableType())
        }
        
        sharingAddRightHoldersView?.showTablesSegmentedControl()
        
        sharingAddRightHoldersView?.searchResultsTable.removeFromSuperview()
    }
}

// MARK: - Describe uses tables in enum
extension ASCSharingAddRightHoldersViewController {
    enum RightHoldersTableType: Int, CaseIterable {
        case users
        case groups
        
        func getTitle() -> String {
            switch self {
            case .users:
                return NSLocalizedString("Users", comment: "")
            case .groups:
                return NSLocalizedString("Groups", comment: "")
            }
        }
    }
}
