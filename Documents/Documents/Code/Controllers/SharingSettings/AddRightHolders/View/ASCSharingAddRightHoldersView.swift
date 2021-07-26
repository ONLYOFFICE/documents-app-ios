//
//  ASCSharingAddRightHoldersView.swift
//  Documents
//
//  Created by Павел Чернышев on 08.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

typealias RightHoldersTableType = ASCSharingAddRightHoldersViewController.RightHoldersTableType

protocol ASCSharingAddRightHoldersViewDelegate: AnyObject {
    func getAccessList() -> ([ASCShareAccess])
    func getCurrentAccess() -> ASCShareAccess
    
    @available(iOS 14.0, *)
    func onAccessMenuSelectAction(action: UIAction, shareAccessRaw: Int)
    func onAccessSheetSelectAction(shareAccessRaw: Int)
    func onUpdateToolbarItems(_ items: [UIBarButtonItem]?)
    func onNextButtonTapped()
    func onCancelBurronTapped()
    func onSelectAllButtonTapped()
    
    func present(sheetAccessController: UIViewController)
}

class ASCSharingAddRightHoldersView {
    weak var view: UIView!
    weak var navigationController: UINavigationController?
    weak var navigationItem: UINavigationItem!
    weak var delegate: ASCSharingAddRightHoldersViewDelegate?
    
    var defaultSelectedTable: RightHoldersTableType = .users
    
    private(set) var searchController = UISearchController(searchResultsController: nil)
    var searchControllerDelegate: UISearchControllerDelegate!
    var searchResultsUpdating: UISearchResultsUpdating!
    var searchBarDelegate: UISearchBarDelegate!
    
    lazy var usersTableView = UITableView()
    lazy var groupsTableView = UITableView()
    lazy var searchResultsTable = UITableView()
    
    // MARK: - Activity indicators
    
    public lazy var loadingUsersTableActivityIndicator = UIActivityIndicatorView()
    public lazy var loadingGroupsTableActivityIndicator = UIActivityIndicatorView()
    
    // MARK: - Navigation bar props
    let title = NSLocalizedString("Shared access", comment: "")
    
    private lazy var cancelBarBtn: UIBarButtonItem = {
        UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: #selector(onCancelButtonTapped))
    }()
    
    private lazy var selectAllBarBtn: UIBarButtonItem = {
        UIBarButtonItem(title: NSLocalizedString("Select all", comment: ""), style: .plain, target: self, action: #selector(onSelectAllButtonTapped))
    }()
    
    // MARK: - Darken screen props
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
    
    // MARK: - Empty view props
    private lazy var emptyView: ASCDocumentsEmptyView? = {
        guard let view = UIView.loadFromNib(named: String(describing: ASCDocumentsEmptyView.self)) as? ASCDocumentsEmptyView else { return nil }
        view.actionButton.removeFromSuperview()
        view.imageView.image = ImageAsset(name: "empty-search-result").image
        view.titleLabel.text = NSLocalizedString("No search results", comment: "")
        view.subtitleLabel.text = nil
        return view
    }()
    
    // MARK: - Toolbar props
    @available(iOS 14.0, *)
    private var accessBarBtnMenu: UIMenu {
        let accessList = delegate?.getAccessList() ?? []
        let menuItems = accessList
            .map({ access in
                UIAction(title: access.title(),
                         image: access.image(),
                         state: access == self.delegate?.getCurrentAccess() ? .on : .off,
                         handler: { [access] action in self.onAccessMenuSelectAction(action: action, shareAccessRaw: access.rawValue) })
            })
        return UIMenu(title: "", children: menuItems)
    }
    
    private lazy var keyboardToolbar: UIToolbar = {
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.width, height: 44))
        bar.translatesAutoresizingMaskIntoConstraints = true
        bar.items = makeToolbarItems()
        bar.sizeToFit()
        return bar
    }()
    
    // MARK: - Keyboard props
    var dispalayingKeyboardFrame: CGRect?
    
    // MARK: - Init
    init(
        view: UIView,
        navigationItem: UINavigationItem,
        navigationController: UINavigationController?,
        searchControllerDelegate: UISearchControllerDelegate,
        searchResultsUpdating: UISearchResultsUpdating,
        searchBarDelegate: UISearchBarDelegate
    ) {
        self.view = view
        self.navigationController = navigationController
        self.navigationItem = navigationItem
        self.searchControllerDelegate = searchControllerDelegate
        self.searchResultsUpdating = searchResultsUpdating
        self.searchBarDelegate = searchBarDelegate
    }
    
    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func load() {
        if #available(iOS 13.0, *) {
            view?.backgroundColor = .systemBackground
        } else {
            view?.backgroundColor = .white
        }
        notificationsRegister()
        configureNavigationBar()
        configureTables()
        configureToolBar()
    }
    
    func reset() {
        usersTableView.reloadData()
        groupsTableView.reloadData()
        searchResultsTable.reloadData()
        searchController.dismiss(animated: false)
        searchController.isActive = false
        searchController.searchBar.text = nil
        searchController.delegate = nil
        searchController.searchBar.delegate = nil
        searchController.searchResultsUpdater = nil
        searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = nil
        
        showTable(tableType: defaultSelectedTable)
        removeDarkenFromScreen()
        navigationController?.isToolbarHidden = false
        updateTitle(withSelectedCount: 0)
        
    }
    
    func updateTitle(withSelectedCount selected: Int) {
        navigationItem.setTitle(title,
                                subtitle: String.localizedStringWithFormat(
                                    NSLocalizedString("%d selected", comment:"Count of seclected rows: count + selected"), selected)
        )
    }
    
    public func showEmptyView(_ show: Bool) {
        guard let emptyView = emptyView else {
            return
        }
        if show {
            searchResultsTable.addSubview(emptyView)
            
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            emptyView.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true
        } else {
            emptyView.removeFromSuperview()
        }
    }
}

// MARK: - @OBJC func delegate
extension ASCSharingAddRightHoldersView {    
    @available(iOS 14.0, *)
    @objc func onAccessMenuSelectAction(action: UIAction, shareAccessRaw: Int) {
        delegate?.onAccessMenuSelectAction(action: action, shareAccessRaw: shareAccessRaw)
        updateToolbars()
    }
    
    @objc func onAccessSheetSelectAction(shareAccessRaw: Int) {
        delegate?.onAccessSheetSelectAction(shareAccessRaw: shareAccessRaw)
        updateToolbars()
    }
    
    @objc func showAccessSheet() {
        let accessController = UIAlertController(
            title: NSLocalizedString("Selecting access rights", comment: ""),
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )
        let accessList = delegate?.getAccessList() ?? []
        accessList.forEach({ access in
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
        
        delegate?.present(sheetAccessController: accessController)
    }
    
    @objc func onNextButtonTapped() {
        delegate?.onNextButtonTapped()
    }
    
    @objc func onCancelButtonTapped() {
        delegate?.onCancelBurronTapped()
    }
    
    @objc func onSelectAllButtonTapped() {
        delegate?.onSelectAllButtonTapped()
    }
}

// MARK: - Navigation bar methods
extension ASCSharingAddRightHoldersView {
    func configureNavigationBar() {
        configureSearchController()
        updateTitle(withSelectedCount: 0)
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.leftBarButtonItem = cancelBarBtn
        navigationItem.rightBarButtonItem = selectAllBarBtn
        guard let navigationController = navigationController else {
            return
        }
        navigationController.navigationBar.barStyle = .default
        navigationController.navigationBar.layer.borderWidth = 0
        navigationController.navigationBar.barTintColor = getNavigationBarColor()
        navigationController.navigationBar.shadowImage = UIImage()
    }
      
    private func getNavigationBarColor() -> UIColor {
        if #available(iOS 13.0, *) {
            return .secondarySystemBackground
        } else {
            return .Light.secondarySystemBackground
        }
    }
    
    private func configureSearchController() {
        searchController.delegate = searchControllerDelegate
        searchController.searchResultsUpdater = searchResultsUpdating
        searchController.searchBar.delegate = searchBarDelegate
        searchController.obscuresBackgroundDuringPresentation  = false
        searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "")
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = RightHoldersTableType.allCases.map({ $0.getTitle() })
        if UIDevice.phone {
            searchController.searchBar.inputAccessoryView = keyboardToolbar
        }
        navigationItem.searchController = searchController
    }
}

// MARK: - Segmented control methods
extension ASCSharingAddRightHoldersView {
        
    func showTablesSegmentedControl() {
        if #available(iOS 13.0, *) {
            searchController.searchBar.setShowsScope(true, animated: true)
        } else {
            self.searchController.searchBar.showsScopeBar = true
        }
    }
    
    func hideTablesSegmentedControl() {
        if #available(iOS 13.0, *) {
            self.searchController.searchBar.setShowsScope(false, animated: true)
        } else {
            self.searchController.searchBar.showsScopeBar = false
        }
    }
}

// MARK: - Table views methods
extension ASCSharingAddRightHoldersView {
    
    private func configureTables() {
        let tables = RightHoldersTableType.allCases.map({ getTableView(byRightHoldersTableType: $0 )}) + [searchResultsTable]
        configureGeneralsParams(forTableViews: tables)
        
        if #available(iOS 13.0, *) {
            searchResultsTable.backgroundColor = .systemBackground
        } else {
            searchResultsTable.backgroundColor = .white
        }
    }
    
    private func configureGeneralsParams(forTableViews tableViews: [UITableView]) {
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
    
    func showTable(tableType: RightHoldersTableType) {
        let tableView = getTableView(byRightHoldersTableType: tableType)
        view.addSubview(tableView)
        tableView.fillToSuperview()
        RightHoldersTableType.allCases.filter({ $0 != tableType }).forEach { type in
            getTableView(byRightHoldersTableType: type).removeFromSuperview()
        }
    }
    
    func showSearchResultTable() {
        view.addSubview(searchResultsTable)
        
        var bottomOffset: CGFloat = 0
        let keyboradHeigh = (dispalayingKeyboardFrame?.height ?? 0)
        if UIDevice.phone {
            bottomOffset = keyboradHeigh
        }
        
        NSLayoutConstraint.activate([
            searchResultsTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchResultsTable.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchResultsTable.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            searchResultsTable.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomOffset)
        ])
    }
    
    func getTableView(byRightHoldersTableType rightHoldersTableType: RightHoldersTableType) -> UITableView {
        switch rightHoldersTableType {
        case .users: return usersTableView
        case .groups: return groupsTableView
        }
    }
}

// MARK: - Darken screen methods
extension ASCSharingAddRightHoldersView {
    func darkenScreen() {
        view.addSubview(darkeingView)
        NSLayoutConstraint.activate([
            darkeingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            darkeingView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            darkeingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            darkeingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func removeDarkenFromScreen() {
        darkeingView.removeFromSuperview()
    }
}

// MARK: - Toolbar methods
extension ASCSharingAddRightHoldersView {
    
    func configureToolBar() {
        self.navigationController?.isToolbarHidden = false
        delegate?.onUpdateToolbarItems(makeToolbarItems())
    }
    
    private func makeToolbarItems() -> [UIBarButtonItem] {
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let currentAccess = delegate?.getCurrentAccess() ?? .none
        let accessBarBtnItem = makeAccessBarBtn(title: currentAccess.title(), image: currentAccess.image())
        return [accessBarBtnItem, spaceItem, makeNextBarBtn()]
    }
    
    private func makeAccessBarBtn(title: String, image: UIImage?) -> UIBarButtonItem  {
        let barBtn = UIButton(type: .system)
        barBtn.setTitle(title, for: .normal)
        barBtn.setImage(image, for: .normal)
        barBtn.contentEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 8)
        barBtn.titleEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: -barBtn.contentEdgeInsets.right)
        barBtn.titleLabel?.font = .systemFont(ofSize: 17)
        barBtn.tintColor = Asset.Colors.brend.color
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
        nextBtn.layer.cornerRadius = 13
        nextBtn.setTitle(NSLocalizedString("Next", comment: "").uppercased(), for: .normal)
        nextBtn.contentEdgeInsets = UIEdgeInsets(top: 3, left: 15, bottom: 3, right: 15)
        nextBtn.addTarget(self, action: #selector(onNextButtonTapped), for: .touchUpInside)
        return UIBarButtonItem(customView: nextBtn)
    }
    
    public func updateToolbars() {
        delegate?.onUpdateToolbarItems(makeToolbarItems())
        if UIDevice.phone {
            keyboardToolbar.items = makeToolbarItems()
        }
    }
}

// MARK: - Keyboard appear \ desappear
extension ASCSharingAddRightHoldersView {
    
    private func notificationsRegister() {
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
}

// MARK: - Activity indicators funcs
extension ASCSharingAddRightHoldersView {
    
    public func runUsersLoadingAnimation() {
        showTableLoadingActivityIndicator(tableView: usersTableView, activityIndicator: loadingUsersTableActivityIndicator)
    }
    
    public func stopUsersLoadingAnimation() {
        hideTableLoadingActivityIndicator(activityIndicator: loadingUsersTableActivityIndicator)
    }
    
    public func runGroupsLoadingAnimation() {
        showTableLoadingActivityIndicator(tableView: groupsTableView, activityIndicator: loadingGroupsTableActivityIndicator)
    }
    
    public func stopGroupsLoadingAnimation() {
        hideTableLoadingActivityIndicator(activityIndicator: loadingGroupsTableActivityIndicator)
    }
    
    private func showTableLoadingActivityIndicator(tableView: UITableView, activityIndicator loadingTableActivityIndicator: UIActivityIndicatorView) {
        loadingTableActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingTableActivityIndicator.startAnimating()
        tableView.addSubview(loadingTableActivityIndicator)
        loadingTableActivityIndicator.anchorCenterSuperview()
    }
    
    private func hideTableLoadingActivityIndicator(activityIndicator loadingTableActivityIndicator: UIActivityIndicatorView) {
        loadingTableActivityIndicator.stopAnimating()
        loadingTableActivityIndicator.removeFromSuperview()
    }
}
