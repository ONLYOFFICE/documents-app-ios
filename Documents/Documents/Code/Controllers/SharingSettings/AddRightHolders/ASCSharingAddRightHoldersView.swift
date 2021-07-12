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
    func tablesSegmentedControlDidChanged()
    func getAccessList() -> ([ASCShareAccess])
    func getCurrentAccess() -> ASCShareAccess
    
    @available(iOS 14.0, *)
    func onAccessMenuSelectAction(action: UIAction, shareAccessRaw: Int)
    func onAccessSheetSelectAction(shareAccessRaw: Int)
    func onUpdateToolbarItems(_ items: [UIBarButtonItem]?)
    
    func present(sheetAccessController: UIViewController)
}

class ASCSharingAddRightHoldersView {
    weak var view: UIView!
    weak var navigationController: UINavigationController?
    weak var navigationItem: UINavigationItem!
    weak var delegate: ASCSharingAddRightHoldersViewDelegate?
    
    var defaultSelectedTable: RightHoldersTableType = .users
    
    let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - Segmented control props
    private lazy var tablesSegmentedControlView: UIView = {
        let view = UIView()
        view.backgroundColor = getNavigationBarColor()
        return view
    }()

    private(set) lazy var tablesSegmentedControl: UISegmentedControl = {
        var items: [String] = RightHoldersTableType.allCases.map({ $0.getTitle() })
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = defaultSelectedTable.rawValue
        control.addTarget(self, action: #selector(tablesSegmentedControlDidChanged), for: .valueChanged)
        return control
    }()
    
    // MARK: - Table views properties
    var activeTableConstraintToViewTop: NSLayoutConstraint?
    var activeTableConstraintToTableSegment: NSLayoutConstraint?
    
    lazy var usersTableView = UITableView()
    lazy var groupsTableView = UITableView()
    lazy var searchResultsTable = UITableView()
    
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
        let bar = UIToolbar()
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
        searchResultsUpdating: UISearchResultsUpdating
    ) {
        self.view = view
        self.navigationController = navigationController
        self.navigationItem = navigationItem
        searchController.delegate = searchControllerDelegate
        searchController.searchResultsUpdater = searchResultsUpdating
    }
    
    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func load() {
        view?.backgroundColor = .white
        
        notificationsRegister()
        configureNavigationBar()
        configureSegmentedControl()
        configureTables()
        configureToolBar()
    }
    
    func reset() {
        usersTableView.reloadData()
        groupsTableView.reloadData()
        searchResultsTable.reloadData()
        searchController.searchBar.text = nil
        searchController.isActive = false
        searchController.dismiss(animated: false)
        tablesSegmentedControl.selectedSegmentIndex = defaultSelectedTable.rawValue
        showTable(tableType: defaultSelectedTable)
        removeDarkenFromScreen()
    }
}

// MARK: - @OBJC func delegate
extension ASCSharingAddRightHoldersView {
    @objc func tablesSegmentedControlDidChanged() {
        delegate?.tablesSegmentedControlDidChanged()
    }
    
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
}


// MARK: - Navigation bar methods
extension ASCSharingAddRightHoldersView {
    private func configureNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
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
      
    private func getNavigationBarColor() -> UIColor {
        if #available(iOS 13.0, *) {
            return .secondarySystemBackground
        } else {
            return .Light.secondarySystemBackground
        }
    }
}

// MARK: - Segmented control methods
extension ASCSharingAddRightHoldersView {
    private func configureSegmentedControl() {
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
        
    func showTablesSegmentedControl() {
        tablesSegmentedControl.isHidden = false
        UIView.animate(withDuration: 0.4, animations: {
            self.tablesSegmentedControl.alpha = 1
        })
        
        UIView.animate(withDuration: 0.4) {
            self.activeTableConstraintToTableSegment?.isActive = true
            self.activeTableConstraintToViewTop?.isActive = false
            self.view.layoutIfNeeded()
        }
    }
    
    func hideTablesSegmentedControl() {
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
}

// MARK: - Table views methods
extension ASCSharingAddRightHoldersView {
    
    private func configureTables() {
        let tables = RightHoldersTableType.allCases.map({ getTableView(byRightHoldersTableType: $0 )}) + [searchResultsTable]
        configureGeneralsParams(forTableViews: tables)
        searchResultsTable.backgroundColor = .white
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
        activeTableConstraintToViewTop = tableView.topAnchor.constraint(equalTo:  view.safeAreaLayoutGuide.topAnchor)
        activeTableConstraintToTableSegment = tableView.topAnchor.constraint(equalTo: tablesSegmentedControlView.bottomAnchor)
        NSLayoutConstraint.activate([tablesSegmentedControlView.isHidden ? activeTableConstraintToViewTop! : activeTableConstraintToTableSegment!,
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        RightHoldersTableType.allCases.filter({ $0 != tableType }).forEach { type in
            getTableView(byRightHoldersTableType: type).removeFromSuperview()
        }
    }
    
    func showSearchResultTable() {
        view.addSubview(searchResultsTable)
        
        let keyboradHeigh = (dispalayingKeyboardFrame?.height ?? 0)
        
        NSLayoutConstraint.activate([
            searchResultsTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchResultsTable.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchResultsTable.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            searchResultsTable.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboradHeigh)
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
        searchController.searchBar.inputAccessoryView = keyboardToolbar
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
    
    public func updateToolbars() {
        delegate?.onUpdateToolbarItems(makeToolbarItems())
        keyboardToolbar.items = makeToolbarItems()
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

