//
//  ASCSharingAddRightHoldersView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 08.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingAddRightHoldersViewDelegate: AnyObject {
    func getAccessList() -> ([ASCShareAccess])
    func getCurrentAccess() -> ASCShareAccess

    @available(iOS 14.0, *)
    func onAccessMenuSelectAction(action: UIAction, shareAccessRaw: Int)
    func onAccessSheetSelectAction(shareAccessRaw: Int)
    func onUpdateToolbarItems(_ items: [UIBarButtonItem]?)
    func onNextButtonTapped()
    func onSelectAllButtonTapped()
    func onDeselectAllButtonTapped()
    func onDismissButtonTapped()

    func present(sheetAccessController: UIViewController)
}

class ASCSharingAddRightHoldersView {
    weak var view: UIView!
    weak var viewController: UIViewController?
    weak var navigationController: UINavigationController?
    weak var navigationItem: UINavigationItem!
    weak var delegate: ASCSharingAddRightHoldersViewDelegate?

    var defaultSelectedTable: RightHoldersTableType = .users

    private(set) var searchController = UISearchController(searchResultsController: nil)
    var searchControllerDelegate: UISearchControllerDelegate!
    var searchResultsUpdating: UISearchResultsUpdating!
    var searchBarDelegate: UISearchBarDelegate!
    var showsScopeBar: Bool

    lazy var usersTableView = UITableView(frame: .zero, style: .insetGrouped)
    lazy var groupsTableView = UITableView(frame: .zero, style: .insetGrouped)
    lazy var searchResultsTable = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Activity indicators

    public lazy var loadingUsersTableActivityIndicator = UIActivityIndicatorView()
    public lazy var loadingGroupsTableActivityIndicator = UIActivityIndicatorView()

    // MARK: - Navigation bar props

    let title = NSLocalizedString("Shared access", comment: "")
    
    private lazy var closeBarBtn: UIBarButtonItem = UIBarButtonItem(
        title: NSLocalizedString("Close", comment: ""),
        style: .plain,
        target: self,
        action: #selector(onDismissButtonTapped)
    )

    private lazy var selectAllBarBtn: UIBarButtonItem = UIBarButtonItem(
        title: NSLocalizedString("Select all", comment: ""),
        style: .plain,
        target: self,
        action: #selector(onSelectAllButtonTapped)
    )

    private lazy var deselectAllBarBtn: UIBarButtonItem = UIBarButtonItem(
        title: NSLocalizedString("Deselect all", comment: ""),
        style: .plain,
        target: self,
        action: #selector(onDeselectAllButtonTapped)
    )

    // MARK: - Darken screen props

    private lazy var darkeingView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var isDarken: Bool {
        darkeingView.superview != nil
    }

    // MARK: - Empty view props

    private lazy var emptyView: ASCDocumentsEmptyView? = {
        guard let view = UIView.loadFromNib(named: String(describing: ASCDocumentsEmptyView.self)) as? ASCDocumentsEmptyView else { return nil }
        view.type = .search
        return view
    }()

    // MARK: - Modal size props

    var defaultPresentingViewSize = CGSize(width: 540, height: 620)

    // MARK: - Toolbar props

    var isNextBarBtnEnabled = false {
        didSet {
            updateToolbars()
        }
    }

    @available(iOS 14.0, *)
    private var accessBarBtnMenu: UIMenu {
        let accessList = delegate?.getAccessList() ?? []
        let menuItems = accessList
            .map { access in
                UIAction(title: access.title(),
                         image: access.image(),
                         state: access == self.delegate?.getCurrentAccess() ? .on : .off,
                         handler: { [access] action in self.onAccessMenuSelectAction(action: action, shareAccessRaw: access.rawValue) })
            }
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
        searchBarDelegate: UISearchBarDelegate,
        showsScopeBar: Bool
    ) {
        self.view = view
        self.navigationController = navigationController
        self.navigationItem = navigationItem
        self.searchControllerDelegate = searchControllerDelegate
        self.searchResultsUpdating = searchResultsUpdating
        self.searchBarDelegate = searchBarDelegate
        self.showsScopeBar = showsScopeBar
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
        configureToolBar()
        configureTables()
    }

    func reset() {
        resetModalSize()
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
        if selected < 1 {
            navigationItem.setTitle(title, subtitle: nil)
        } else {
            navigationItem.setTitle(title,
                                    subtitle: String.localizedStringWithFormat(
                                        NSLocalizedString("%d selected", comment: "Count of seclected rows: count + selected"), selected
                                    ))
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
        accessList.forEach { access in
            accessController.addAction(UIAlertAction(
                title: access.title(),
                style: access == .deny ? .destructive : .default,
                handler: { [unowned self] _ in self.onAccessSheetSelectAction(shareAccessRaw: access.rawValue) }
            ))
        }

        accessController.addAction(
            UIAlertAction(
                title: ASCLocalization.Common.cancel,
                style: .cancel,
                handler: nil
            )
        )

        delegate?.present(sheetAccessController: accessController)
    }

    @objc func onNextButtonTapped() {
        delegate?.onNextButtonTapped()
    }

    @objc func onSelectAllButtonTapped() {
        delegate?.onSelectAllButtonTapped()
    }

    @objc func onDeselectAllButtonTapped() {
        delegate?.onDeselectAllButtonTapped()
    }
    
    @objc func onDismissButtonTapped() {
        delegate?.onDismissButtonTapped()
    }
}

// MARK: - Navigation bar methods

extension ASCSharingAddRightHoldersView {
    func configureNavigationBar() {
        configureSearchController()
        updateTitle(withSelectedCount: 0)
        navigationItem.leftBarButtonItem = closeBarBtn
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesSearchBarWhenScrolling = false
        guard let navigationController = navigationController else {
            return
        }
        navigationController.navigationBar.barStyle = .default
        navigationController.navigationBar.layer.borderWidth = 0
        navigationController.navigationBar.barTintColor = getNavigationBarColor()
        navigationController.navigationBar.shadowImage = UIImage()
    }

    func showSelectBarBtn() {
        navigationItem.rightBarButtonItem = selectAllBarBtn
    }

    func clearSearchBar() {
        searchController.dismiss(animated: false)
        searchController.isActive = false
        searchController.searchBar.text = nil
    }

    func showDeselectBarBtn() {
        navigationItem.rightBarButtonItem = deselectAllBarBtn
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
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "")
        searchController.searchBar.showsScopeBar = showsScopeBar
        if showsScopeBar {
            searchController.searchBar.scopeButtonTitles = RightHoldersTableType.allCases.map { $0.getTitle() }
        }
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
            searchController.searchBar.showsScopeBar = true
        }
    }

    func hideTablesSegmentedControl() {
        if #available(iOS 13.0, *) {
            self.searchController.searchBar.setShowsScope(false, animated: true)
        } else {
            searchController.searchBar.showsScopeBar = false
        }
    }
}

// MARK: - Table views methods

extension ASCSharingAddRightHoldersView {
    private func configureTables() {
        let tables = RightHoldersTableType.allCases.map { getTableView(byRightHoldersTableType: $0) } + [searchResultsTable]
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
            if #available(iOS 15.0, *) {} else {
                tableView.backgroundColor = Asset.Colors.tableBackground.color
            }
            tableView.sectionFooterHeight = 0
            tableView.setEditing(true, animated: false)
            tableView.allowsSelectionDuringEditing = true
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.allowsMultipleSelectionDuringEditing = true
            tableView.keyboardDismissMode = .onDrag
        }
    }

    func showTable(tableType: RightHoldersTableType) {
        let tableView = getTableView(byRightHoldersTableType: tableType)
        view.addSubview(tableView)
        tableView.fillToSuperview()
        RightHoldersTableType.allCases.filter { $0 != tableType }.forEach { type in
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
            searchResultsTable.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomOffset),
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
            darkeingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    func removeDarkenFromScreen() {
        darkeingView.removeFromSuperview()
    }
}

// MARK: - Empty view methods

extension ASCSharingAddRightHoldersView {
    public func showEmptyView(_ show: Bool) {
        guard let emptyView = emptyView else {
            return
        }
        if show {
            emptyView.removeFromSuperview()
            emptyView.frame = searchResultsTable.frame

            if UIDevice.pad,
               let preferedContentHeight = viewController?.preferredContentSize.height,
               preferedContentHeight > 0,
               preferedContentHeight < 500
            {
                emptyView.imageView.image = nil
                emptyView.frame = searchResultsTable.frame.offsetBy(dx: 0, dy: preferedContentHeight / 2 - 100)
            } else if emptyView.imageView.image == nil {
                emptyView.type = .search
            }

            if UIDevice.phone {
                emptyView.frame = searchResultsTable.frame.offsetBy(dx: 0, dy: 75)
            }

            searchResultsTable.addSubview(emptyView)
        } else {
            emptyView.removeFromSuperview()
        }
    }

    func reloadEmptyViewIfNeeded() {
        if emptyView?.superview != nil {
            showEmptyView(true)
        }
    }
}

// MARK: - Toolbar methods

extension ASCSharingAddRightHoldersView {
    func configureToolBar() {
        navigationController?.isToolbarHidden = false
        delegate?.onUpdateToolbarItems(makeToolbarItems())
    }

    private func makeToolbarItems() -> [UIBarButtonItem] {
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let currentAccess = delegate?.getCurrentAccess() ?? .none
        let accessBarBtnItem = makeAccessBarBtn(title: currentAccess.title(), image: currentAccess.image())
        return [accessBarBtnItem, spaceItem, makeNextBarBtn()]
    }

    private func makeAccessBarBtn(title: String, image: UIImage?) -> UIBarButtonItem {
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
        nextBtn.styleType = .capsule
        nextBtn.setTitleForAllStates(NSLocalizedString("Next", comment: "").uppercased())
        nextBtn.addTarget(self, action: #selector(onNextButtonTapped), for: .touchUpInside)
        nextBtn.isEnabled = isNextBarBtnEnabled
        nextBtn.enableMode = isNextBarBtnEnabled ? .enabled : .disabled

        let barItem = UIBarButtonItem(customView: nextBtn)
        barItem.isEnabled = isNextBarBtnEnabled
        return barItem
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
        if UIDevice.pad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.changeModalHeightIfNeeded(keyboardSize: keyboardFrame)
                self.reloadEmptyViewIfNeeded()
            }
        }
    }

    @objc func keyboardWillHide(sender: NSNotification) {
        dispalayingKeyboardFrame = nil
        if UIDevice.pad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.resetModalSizeIfNeeded()
            }
        }
    }

    private func getKeyboardFrame(bySenderNotification sender: NSNotification) -> CGRect? {
        guard let userInfo = sender.userInfo else { return nil }
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return nil }
        return keyboardSize.cgRectValue
    }
}

// MARK: - Modal size funcs

extension ASCSharingAddRightHoldersView {
    func saveCurrentPreferredSizeAsDefault() {
        if UIDevice.pad, let presentingViewSize = ASCViewControllerManager.shared.topViewController?.view.size {
            let navBarHeight = navigationController?.navigationBar.height ?? 0
            let toolbarHeigh = navigationController?.toolbar.height ?? 0
            defaultPresentingViewSize = CGSize(width: presentingViewSize.width, height: presentingViewSize.height - toolbarHeigh - navBarHeight)
        }
    }

    func changeModalHeightIfNeeded(keyboardSize: CGRect) {
        guard UIDevice.pad else { return }
        let presentingViewHeight = view.size.height
        let modalHeigh = presentingViewHeight > 0 && presentingViewHeight < UIScreen.main.bounds.height
            ? presentingViewHeight
            : defaultPresentingViewSize.height

        let spaceAroundModalHeight: CGFloat = 150
        let freeSpace = max(0, UIScreen.main.bounds.height - modalHeigh - spaceAroundModalHeight)

        if keyboardSize.height > freeSpace {
            let differance = keyboardSize.height - freeSpace
            let minModalHeight: CGFloat = 150
            let newModelHeight = max(view.frame.height - differance, minModalHeight)
            log.info("new model height", newModelHeight)
            navigationController?.preferredContentSize.height = newModelHeight
            viewController?.preferredContentSize.height = newModelHeight
        } else {
            log.info("new model size is default")
            resetModalSizeIfNeeded()
        }
    }

    func resetModalSizeIfNeeded() {
        let didPreferredContentSizeChange = navigationController?.preferredContentSize.height ?? 0 > 0
            || navigationController?.preferredContentSize.width ?? 0 > 0
        if UIDevice.pad, didPreferredContentSizeChange {
            resetModalSize()
        }
    }

    func resetModalSize() {
        navigationController?.preferredContentSize = CGSize(width: 0, height: 0)
        viewController?.preferredContentSize = CGSize(width: 0, height: 0)
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
        let navBarHeight = navigationController?.navigationBar.height ?? 0
        let searchBarHeight = searchController.searchBar.height
        let centerYOffset = (navBarHeight + searchBarHeight) / 2

        loadingTableActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingTableActivityIndicator.startAnimating()
        tableView.addSubview(loadingTableActivityIndicator)
        loadingTableActivityIndicator.anchorCenterXToSuperview()
        loadingTableActivityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -centerYOffset).isActive = true
    }

    private func hideTableLoadingActivityIndicator(activityIndicator loadingTableActivityIndicator: UIActivityIndicatorView) {
        loadingTableActivityIndicator.stopAnimating()
        loadingTableActivityIndicator.removeFromSuperview()
    }
}
