//
//  ASCAddRightHoldersViewController.swift
//  Documents
//
//  Created by Павел Чернышев on 15.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingAddRightHoldersViewController: UIViewController {
    
    var defaultSelectedTable: RightHoldersTableType = .users
    
    let defaultAccess: ASCShareAccess = .read
    lazy var selectedAccess: ASCShareAccess = self.defaultAccess
    
    var activeTableConstraintToViewTop: NSLayoutConstraint?
    var activeTableConstraintToTableSegment: NSLayoutConstraint?
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var isSearchBarEmpty: Bool {
        guard let text = searchController.searchBar.text else {
            return false
        }
        return text.isEmpty
    }
    
    private lazy var usersTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<ASCSharingAddRightHoldersUserTableViewCell>(models: self.usersModels)
    private lazy var groupsTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<ASCSharingAddRightHoldersGroupTableViewCell>(models: self.groupsModels)
    
    private lazy var tablesSegmentedControl: UISegmentedControl = {
        var items: [String] = RightHoldersTableType.allCases.map({ $0.getTitle() })
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = defaultSelectedTable.rawValue
        control.addTarget(self, action: #selector(tablesSegmentedControlDidChanged), for: .valueChanged)
        return control
    }()
    
    private lazy var tablesSegmentedControlView: UIView = {
        let view = UIView()
        view.backgroundColor = getNavigationBarColor()
        return view
    }()
    
    private lazy var usersTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = usersTableViewDataSourceAndDelegate
        tableView.delegate = usersTableViewDataSourceAndDelegate
        return tableView
    }()
    
    private lazy var groupsTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = groupsTableViewDataSourceAndDelegate
        tableView.delegate = groupsTableViewDataSourceAndDelegate
        return tableView
    }()
    
    private lazy var accessBarBtnItem: UIBarButtonItem = makeAccessBarBtn(title: defaultAccess.title(), image: defaultAccess.image())
    
    @available(iOS 14.0, *)
    private var accessBarBtnMenu: UIMenu {
        let menuItems = ASCShareAccess.allCases
            .filter({ $0 != .none })
            .map({ access in
                UIAction(title: access.title(),
                         image: access.image(),
                         state: access == self.selectedAccess ? .on : .off,
                         handler: { [access] action in self.onAccessMenuSelectAction(action: action, shareAccessRaw: access.rawValue) })
            })
        return UIMenu(title: "", children: menuItems)
    }
    
    private lazy var nextBarBtnItem: UIBarButtonItem = {
        let nextBtn = ASCButtonStyle()
        nextBtn.layer.cornerRadius = 12
        nextBtn.setTitle(NSLocalizedString("Next", comment: "").uppercased(), for: .normal)
        nextBtn.contentEdgeInsets = UIEdgeInsets(top: 3, left: 15, bottom: 3, right: 15)
        return UIBarButtonItem(customView: nextBtn)
    }()
    
    private lazy var darkeingView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.25
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var isDarken: Bool {
        darkeingView.superview != nil
    }
    
    var usersModels: [ASCSharingAddRightHolderUserModel] = [
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Abel – Abe, Abie;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Abner – Ab, Abbie;", type: "Manager", isSelected: true),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Abraham, Abram – Abe, Abie, Bram;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Adam – Ad, Addie, Addy, Ade;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Benjamin – Ben, Bennie, Benny, Benjy Benjie;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Bennet, Bennett – Ben, Bennie, Benny;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Bernard, Barnard – Bernie, Berney, Barney, Barnie", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Christopher Kit, Kester, Kristof, Toph,", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Clarence – Clare, Clair;", type: "Manager", isSelected: true),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Clare, Clair;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Clark, Clarke;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Claude, Claud;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Donald – Don, Donnie, Donny", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Donovan – Don, Donnie, Donny;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Dorian;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Dougls, Douglass – Doug;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Doyle;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Drew (see Andrew);", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Elliot, Elliott – El;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Ellis – El;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Elmer – El;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Elton, Alton – El, Al;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Elvin, Elwin, Elwyn – El, Vin, Vinny, Win;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Elvis – El;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Herman – Manny, Mannie;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Hilary, Hillary – Hill, Hillie, Hilly;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Homer;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Horace, Horatio;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Howard – Howie;", type: "Manager"),
        ASCSharingAddRightHolderUserModel(image: Asset.Images.avatarDefault.image, name: "Hubert – Hugh, Bert, Bertie", type: "Manager")
    ]
    
    var groupsModels: [ASCSharingAddRightHoldersGroupModel] = [
        ASCSharingAddRightHoldersGroupModel(image: Asset.Images.avatarDefaultGroup.image, name: "Admins", isSelected: false),
        ASCSharingAddRightHoldersGroupModel(image: Asset.Images.avatarDefaultGroup.image, name: "Disigners", isSelected: false)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        configureNavigationBar()
        configureSegmentedControl()
        configureTables()
        configureToolBar()
    }
    
    private func configureNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation  = false
        searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "")
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        guard let navigationController = navigationController else {
            return
        }
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.barStyle = .default
        navigationController.navigationBar.layer.borderWidth = 0
        navigationController.navigationBar.barTintColor = getNavigationBarColor()
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.backIndicatorImage = nil
        navigationController.navigationBar.backItem?.title = NSLocalizedString("Cancle", comment: "")
        navigationController.navigationBar.topItem?.title = NSLocalizedString("Shared access", comment: "")
    }
    
    func configureSegmentedControl() {
        tablesSegmentedControlView.translatesAutoresizingMaskIntoConstraints = false
        tablesSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        tablesSegmentedControlView.addSubview(tablesSegmentedControl)
        view.addSubview(tablesSegmentedControlView)
        NSLayoutConstraint.activate([
            tablesSegmentedControlView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tablesSegmentedControlView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tablesSegmentedControlView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tablesSegmentedControlView.heightAnchor.constraint(equalToConstant: 40),
            
            tablesSegmentedControl.leadingAnchor.constraint(equalTo: tablesSegmentedControlView.leadingAnchor, constant: 16),
            tablesSegmentedControl.trailingAnchor.constraint(equalTo: tablesSegmentedControlView.trailingAnchor, constant: -16),
            tablesSegmentedControl.topAnchor.constraint(equalTo: tablesSegmentedControlView.topAnchor),
            tablesSegmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    func configureTables() {
        configureGeneralsParams(forTableViews: RightHoldersTableType.allCases.map({ getTable(byRightHoldersTableType: $0 )}))
        
        usersTableView.register(usersTableViewDataSourceAndDelegate.type, forCellReuseIdentifier: usersTableViewDataSourceAndDelegate.type.reuseId)
        groupsTableView.register(groupsTableViewDataSourceAndDelegate.type, forCellReuseIdentifier: groupsTableViewDataSourceAndDelegate.type.reuseId)
    }
    
    func configureGeneralsParams(forTableViews tableViews: [UITableView]) {
        for tableView in tableViews {
            tableView.tableFooterView = UIView()
            tableView.backgroundColor = Asset.Colors.tableBackground.color
            tableView.sectionFooterHeight = 0
            tableView.setEditing(true, animated: false)
            tableView.allowsSelectionDuringEditing = true
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.allowsMultipleSelectionDuringEditing = true
        }
        showTable(tableType: defaultSelectedTable)
    }
    
    private func configureToolBar() {
        self.navigationController?.isToolbarHidden = false
        
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        self.toolbarItems = [accessBarBtnItem, spaceItem, nextBarBtnItem]
    }
    
    private func makeAccessBarBtn(title: String, image: UIImage?) -> UIBarButtonItem  {
        let barBtn = UIButton(type: .system)
        barBtn.setTitle(title, for: .normal)
        barBtn.setImage(image, for: .normal)
        barBtn.contentEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 8)
        barBtn.titleEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: -barBtn.contentEdgeInsets.right)
        barBtn.titleLabel?.font = .systemFont(ofSize: 17)
        let barBtnItem = UIBarButtonItem(customView: barBtn)
        barBtnItem.target = self
        if #available(iOS 14, *) {
            barBtn.showsMenuAsPrimaryAction = true
            barBtn.menu = accessBarBtnMenu
        } else {
            barBtn.addTarget(self, action: #selector(showAccessSheet), for: .touchUpInside)
        }
        
        return barBtnItem
    }
    
    
    @available(iOS 14.0, *)
    @objc func onAccessMenuSelectAction(action: UIAction, shareAccessRaw: Int) {
        onAccessSheetSelectAction(shareAccessRaw: shareAccessRaw)
    }
    
    @objc func showAccessSheet() {
        let accessController = UIAlertController(
            title: NSLocalizedString("Selecting access rights", comment: ""),
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )
        
        ASCShareAccess.allCases
            .filter({ $0 != .none })
            .forEach({ access in
                accessController.addAction(UIAlertAction(
                                            title: access.title(),
                                            style: access == .deny ? .destructive : .default,
                                            handler: { [unowned self] _ in self.onAccessSheetSelectAction(shareAccessRaw: access.rawValue) }))
            })
        
        accessController.addAction(
            UIAlertAction(
                title: ASCLocalization.Common.cancel,
                style: .cancel,
                handler: nil)
        )
        
        present(accessController, animated: true, completion: nil)
    }
    
    @objc func onAccessSheetSelectAction(shareAccessRaw: Int) {
        guard let access = ASCShareAccess(rawValue: shareAccessRaw) else { return }
        self.selectedAccess = access
        if var toolbarItems = toolbarItems {
            toolbarItems.removeFirst()
            toolbarItems.insert(makeAccessBarBtn(title: access.title(), image: access.image()), at: 0)
            self.toolbarItems = toolbarItems
        }
    }
    
    private func showTable(tableType: RightHoldersTableType) {
        let tableView = getTable(byRightHoldersTableType: tableType)
        view.addSubview(tableView)
        activeTableConstraintToViewTop = tableView.topAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.topAnchor)
        activeTableConstraintToTableSegment = tableView.topAnchor.constraint(equalTo: tablesSegmentedControlView.bottomAnchor)
        NSLayoutConstraint.activate([
            activeTableConstraintToTableSegment!,
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        RightHoldersTableType.allCases.filter({ $0 != tableType }).forEach { type in
            getTable(byRightHoldersTableType: type).removeFromSuperview()
        }
    }
    
    private func getNavigationBarColor() -> UIColor {
        if #available(iOS 13.0, *) {
            return .secondarySystemBackground
        } else {
            return .Light.secondarySystemBackground
        }
    }
    
    private func getTable(byRightHoldersTableType rightHoldersTableType: RightHoldersTableType) -> UITableView {
        switch rightHoldersTableType {
        case .users: return usersTableView
        case .groups: return groupsTableView
        }
    }
    
    @objc func tablesSegmentedControlDidChanged() {
        guard let tableType = RightHoldersTableType(rawValue: tablesSegmentedControl.selectedSegmentIndex) else {
            fatalError("Couldn't find a table type for segment control index: \(tablesSegmentedControl.selectedSegmentIndex)")
        }
        showTable(tableType: tableType)
    }
    
    private func darkenScreen() {
        view.addSubview(darkeingView)
        NSLayoutConstraint.activate([
            darkeingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            darkeingView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            darkeingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            darkeingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
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

// MARK: - UI Search results updating
extension ASCSharingAddRightHoldersViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        darkenScreen()
        tablesSegmentedControl.isHidden = true
        activeTableConstraintToTableSegment?.isActive = false
        activeTableConstraintToViewTop?.isActive = true
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        tablesSegmentedControl.isHidden = false
        activeTableConstraintToTableSegment?.isActive = true
        activeTableConstraintToViewTop?.isActive = false
        darkeingView.removeFromSuperview()
    }
}

// MARK: - Users and Groupd TableView data source and delegate
extension ASCSharingAddRightHoldersViewController {
    class ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<T: UITableViewCell & ASCReusedIdentifierProtocol & ASCViewModelSetter>:
        NSObject, UITableViewDataSource, UITableViewDelegate where T.ViewModel: ASCNamedProtocol {
        
        let type = T.self
        var rowHeight: CGFloat = 60
        
        private(set) var selectedRows: [IndexPath] = []
        
        private var groupedModels: [Section] = []
        
        init(models: [T.ViewModel] = []) {
            super.init()
            setModels(models: models)
        }
        
        func setModels(models: [T.ViewModel]) {
            groupedModels = models
                .sorted(by: { $0.name < $1.name })
                .reduce([], { result, model in
                    guard let firstLetter = model.name.first else { return result }
                    guard let section = result.last else {
                        let section =  Section(index: firstLetter, models: [model])
                        return [section]
                    }
                    guard section.index == firstLetter else {
                        var result = result
                        result.append(Section(index: firstLetter, models: [model]))
                        return result
                    }
                    
                    section.models.append(model)
                    
                    return result
                })
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            groupedModels.count
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            groupedModels[section].models.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard var cell = tableView.dequeueReusableCell(withIdentifier: T.reuseId) as? T else {
                fatalError("Couldn't cast cell to \(T.self)")
            }
            let viewModel = groupedModels[indexPath.section].models[indexPath.row]
            cell.viewModel = viewModel
            return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            selectedRows.append(indexPath)
        }
        
        func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
            selectedRows.removeAll(indexPath)
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            rowHeight
        }
        
        func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
            .none
        }
        
        func sectionIndexTitles(for tableView: UITableView) -> [String]? {
            groupedModels.map({ "\($0.index)" })
        }
        
        func tableView(_ tableView: UITableView,
                       sectionForSectionIndexTitle title: String,
                       at index: Int) -> Int {
            return index
        }
        
        class Section {
            var index: Character
            var models: [T.ViewModel]
            
            init(index: Character, models: [T.ViewModel]) {
                self.index = index
                self.models = models
            }
        }
    }
}


