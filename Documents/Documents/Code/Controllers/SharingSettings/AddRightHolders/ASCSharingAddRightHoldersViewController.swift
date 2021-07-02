//
//  ASCAddRightHoldersViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.06.2021.
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
    
    private lazy var usersTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<ASCSharingRightHolderTableViewCell>(models: self.usersModels)
    private lazy var groupsTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<ASCSharingRightHolderTableViewCell>(models: self.groupsModels)
    private lazy var searchResultsTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate(tables: [ .users: usersTableView, .groups: groupsTableView])
    
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
    
    private lazy var searchResultsTable: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = searchResultsTableViewDataSourceAndDelegate
        tableView.delegate = searchResultsTableViewDataSourceAndDelegate
        return tableView
    }()
    
    private lazy var accessBarBtnItem: UIBarButtonItem = makeAccessBarBtn(title: defaultAccess.title(), image: defaultAccess.image())
    
    private lazy var keyboardToolbar: UIToolbar = {
        let bar = UIToolbar()
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        bar.items = [makeAccessBarBtn(title: self.selectedAccess.title(), image: self.selectedAccess.image()), spaceItem, makeNextBarBtn()]
        bar.sizeToFit()
        return bar
    }()
    
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
    
    private lazy var nextBarBtnItem: UIBarButtonItem = makeNextBarBtn()
    
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
    
    private var dispalayingKeyboardFrame: CGRect?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        notificationsReister()
        configureNavigationBar()
        configureSegmentedControl()
        configureTables()
        configureToolBar()
        
        showTable(tableType: defaultSelectedTable)
    }
    
    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func notificationsReister() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        guard let keyboardFrame = getKeyboardFrame(bySenderNotification: sender) else { return }
        dispalayingKeyboardFrame = keyboardFrame
    }
    
    @objc func keyboardWillHide(sender: NSNotification) {
        dispalayingKeyboardFrame = nil
    }
    
    private func getKeyboardFrame(bySenderNotification sender: NSNotification) -> CGRect? {
        guard let userInfo = sender.userInfo else { return nil }
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return nil}
        return keyboardSize.cgRectValue
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
        let tables = RightHoldersTableType.allCases.map({ getTable(byRightHoldersTableType: $0 )}) + [searchResultsTable]
        configureGeneralsParams(forTableViews: tables)
        searchResultsTable.backgroundColor = .white
        
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
    }
    
    private func configureToolBar() {
        self.navigationController?.isToolbarHidden = false
        
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        self.toolbarItems = [accessBarBtnItem, spaceItem, nextBarBtnItem]

        searchController.searchBar.inputAccessoryView = keyboardToolbar
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
    
    private func makeNextBarBtn() -> UIBarButtonItem {
        let nextBtn = ASCButtonStyle()
        nextBtn.layer.cornerRadius = 12
        nextBtn.setTitle(NSLocalizedString("Next", comment: "").uppercased(), for: .normal)
        nextBtn.contentEdgeInsets = UIEdgeInsets(top: 3, left: 15, bottom: 3, right: 15)
        return UIBarButtonItem(customView: nextBtn)
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
        
        if var keyboardToolbarItems = keyboardToolbar.items {
            keyboardToolbarItems.removeFirst()
            keyboardToolbarItems.insert(makeAccessBarBtn(title: access.title(), image: access.image()), at: 0)
            keyboardToolbar.items = keyboardToolbarItems
        }
    }
    
    private func showTable(tableType: RightHoldersTableType) {
        let tableView = getTable(byRightHoldersTableType: tableType)
        view.addSubview(tableView)
        activeTableConstraintToViewTop = tableView.topAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.topAnchor)
        activeTableConstraintToTableSegment = tableView.topAnchor.constraint(equalTo: tablesSegmentedControlView.bottomAnchor)
        NSLayoutConstraint.activate([
            tablesSegmentedControlView.isHidden ? activeTableConstraintToViewTop! : activeTableConstraintToTableSegment!,
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        RightHoldersTableType.allCases.filter({ $0 != tableType }).forEach { type in
            getTable(byRightHoldersTableType: type).removeFromSuperview()
        }
    }
    
    private func showSearchResultTable() {
        view.addSubview(searchResultsTable)
        
        let keyboradHeigh = (dispalayingKeyboardFrame?.height ?? 0)
        
        NSLayoutConstraint.activate([
            searchResultsTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchResultsTable.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchResultsTable.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            searchResultsTable.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboradHeigh)
        ])
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
    
    private func getSelectedTableView() -> UITableView {
        let type = getSelectedTableType()
        return getTable(byRightHoldersTableType: type)
    }
    
    @objc func tablesSegmentedControlDidChanged() {
        let tableType = getSelectedTableType()
        showTable(tableType: tableType)
    }
    
    private func getSelectedTableType() -> RightHoldersTableType {
        guard let tableType = RightHoldersTableType(rawValue: tablesSegmentedControl.selectedSegmentIndex) else {
            fatalError("Couldn't find a table type for segment control index: \(tablesSegmentedControl.selectedSegmentIndex)")
        }
        return tableType
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
    
    private func hideTablesSegmentedControl() {
        UIView.animate(withDuration: 0.4, animations: {
            self.tablesSegmentedControl.alpha = 0
        }) { (finished) in
            self.tablesSegmentedControl.isHidden = true
        }
        
        UIView.animate(withDuration: 0.4) {
            self.activeTableConstraintToTableSegment?.isActive = false
            self.activeTableConstraintToViewTop?.isActive = true
            self.view.layoutIfNeeded()
        }
    }
    
    private func showTablesSegmentedControl() {
        self.tablesSegmentedControl.isHidden = false
        UIView.animate(withDuration: 0.4, animations: {
            self.tablesSegmentedControl.alpha = 1
        })
        
        UIView.animate(withDuration: 0.4) {
            self.activeTableConstraintToTableSegment?.isActive = true
            self.activeTableConstraintToViewTop?.isActive = false
            self.view.layoutIfNeeded()
        }
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
        
        guard !searchText.isEmpty else {
            groupsTableViewDataSourceAndDelegate.setModels(models: groupsModels)
            groupsTableView.reloadData()
            usersTableViewDataSourceAndDelegate.setModels(models: usersModels)
            usersTableView.reloadData()
            searchResultsTable.reloadData()
            return
        }
        
        groupsTableViewDataSourceAndDelegate.setModels(models: groupsModels.filter({ $0.name.lowercased().contains(searchText.lowercased()) }))
        groupsTableView.reloadData()
        usersTableViewDataSourceAndDelegate.setModels(models: usersModels.filter({ $0.name.lowercased().contains(searchText.lowercased()) }))
        usersTableView.reloadData()
        
        if searchResultsTable.superview == nil {
            getSelectedTableView().removeFromSuperview()
            darkeingView.removeFromSuperview()
            showSearchResultTable()
        }
        searchResultsTable.reloadData()
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            self.darkenScreen()
        }
        hideTablesSegmentedControl()
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        self.darkeingView.removeFromSuperview()
        
        self.groupsTableViewDataSourceAndDelegate.setModels(models: groupsModels)
        self.usersTableViewDataSourceAndDelegate.setModels(models: usersModels)
        
        if getSelectedTableView().superview == nil {
            showTable(tableType: self.getSelectedTableType())
        }
        
        showTablesSegmentedControl()

        searchResultsTable.removeFromSuperview()
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

// MARK: - Search table view datasource and delegate
extension ASCSharingAddRightHoldersViewController {
    class ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
        
        let tables:  [RightHoldersTableType: UITableView]
        
        init(tables: [RightHoldersTableType: UITableView]) {
            self.tables = tables
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            tables.count
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let tableKey = Array(tables.keys)[section]
            guard let table = tables[tableKey] else { fatalError("couldn't find table by key \(tableKey)") }
            
            var count = 0
            for tableSection in 0..<table.numberOfSections {
                count += table.numberOfRows(inSection: tableSection)
            }
            
            return count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let tableKey = Array(tables.keys)[indexPath.section]
            guard let table = tables[tableKey] else { fatalError("couldn't find table by key \(tableKey)") }
            return findCell(inTable: table, byRowIndex: indexPath.row)
        }
        
        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let tableKey = Array(tables.keys)[section]
            return tableKey.getTitle()
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            60
        }
        
        private func findCell(inTable table: UITableView, byRowIndex rowIndex: Int) -> UITableViewCell {
            var rowCounter = 0
            for section in 0..<table.numberOfSections {
                for row in 0..<table.numberOfRows(inSection: section) {
                    if rowCounter == rowIndex {
                        
                        guard let cell = table.dataSource?.tableView(table, cellForRowAt: IndexPath(row: row, section: section)) else { return UITableViewCell() }
                        return cell
                    }
                    rowCounter += 1
                }
            }
            fatalError("Couldn't find the cell")
        }
        
        func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            let header = UITableViewHeaderFooterView()
            header.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: section) ?? ""
            header.contentView.backgroundColor = .white
            return header
        }
    }
}


