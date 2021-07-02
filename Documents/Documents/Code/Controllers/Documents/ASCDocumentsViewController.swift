//
//  ASCDocumentsViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 2/2/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import ObjectMapper
import FileKit
import Alamofire
import MBProgressHUD
import MGSwipeTableCell
import SwiftRater
import SpreadsheetEditor
import SwiftMessages

class ASCDocumentsViewController: ASCBaseTableViewController, UIGestureRecognizerDelegate {

    static let identifier = String(describing: ASCDocumentsViewController.self)

    // MARK: - Public

    var folder: ASCFolder? = nil {
        didSet {
            if oldValue == nil && folder != nil {
                loadFirstPage()
            }
        }
    }

    var provider: ASCFileProviderProtocol? {
        didSet {
            if var provider = provider {
                provider.delegate = self
            }
            configureProvider()
        }
    }
    
    // MARK: - Private

    private lazy var loadedDocumentsViewControllerFinder: ASCLoadedViewControllerFinderProtocol = ASCLoadedDocumentViewControllerByProviderAndFolderFinder()
    private var total: Int {
        return provider?.total ?? 0
    }
    
    private var tableData:[ASCEntity] {
        return provider?.items ?? []
    }

    private var selectedIds: Set<String> = []
    private let kPageLoadingCellTag = 7777
    private var highlightEntity: ASCEntity?
    private var hideableViewControllerOnTransition: UIViewController?

    // Navigation bar
    private var addBarButton: UIBarButtonItem? = nil
    private var sortSelectBarButton: UIBarButtonItem? = nil
    private var sortBarButton: UIBarButtonItem? = nil
    private var selectBarButton: UIBarButtonItem? = nil
    private var cancelBarButton: UIBarButtonItem? = nil
    private var selectAllBarButton: UIBarButtonItem? = nil
    
    // Search
    private lazy var searchController: UISearchController = {
        $0.delegate = self
        $0.searchResultsUpdater = self
        $0.dimsBackgroundDuringPresentation = false
        $0.searchBar.searchBarStyle = .minimal
        $0.searchBar.tintColor = view.tintColor

        if #available(iOS 11.0, *) {
            navigationItem.searchController = nil
            navigationItem.hidesSearchBarWhenScrolling = featureLargeTitle
        } else {
            tableView.tableHeaderView = $0.searchBar
        }
        return $0
    }(UISearchController(searchResultsController: nil))
    private lazy var searchBackground: UIView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        $0.backgroundColor = .white
        return $0
    }(UIView())
    private lazy var searchSeparator: UIView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        $0.backgroundColor = .lightGray
        return $0
    }(UIView())
    private lazy var uiRefreshControl: UIRefreshControl = {
        $0.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        return $0
    }(UIRefreshControl())
    private var searchTask: DispatchWorkItem?
    private var searchValue: String?
    
    // Events
    private let events = EventManager()
    
    // Interaction Controller
    fileprivate lazy var documentInteraction: UIDocumentInteractionController = UIDocumentInteractionController()
    
    // Features
    private let featureLargeTitle = true
    
    // Sort
    private lazy var defaultsSortTypes: [ASCDocumentSortType] = [.dateandtime, .az, .type, .size]

    
    // MARK: - Outlets
    
    @IBOutlet var loadingView: UIView!
    @IBOutlet var placeholderContentView: UIView!
    @IBOutlet weak var emptyCreateInfo: UILabel!
    @IBOutlet weak var emptyCreateButton: UIButton!
    @IBOutlet weak var emptyCenterCostraint: NSLayoutConstraint!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var errorSubtitleLabel: UILabel!

    private lazy var emptyView: ASCDocumentsEmptyView? = {
        guard let view = UIView.loadFromNib(named: String(describing: ASCDocumentsEmptyView.self)) as? ASCDocumentsEmptyView else { return nil }

        view.onAction = { [weak self] in
            guard
                let strongSelf = self,
                let folder = strongSelf.folder,
                let provider = strongSelf.provider
            else { return }

            strongSelf.createFirstItem(view.actionButton)
            view.actionButton.isHidden = !provider.allowEdit(entity: folder)
        }
        return view
    }()

    private lazy var errorView: ASCDocumentsEmptyView? = {
        guard let view = UIView.loadFromNib(named: String(describing: ASCDocumentsEmptyView.self)) as? ASCDocumentsEmptyView else { return nil }
        
        view.onAction = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.onErrorRetry(view.actionButton)
        }
        return view
    }()

    private lazy var searchEmptyView: ASCDocumentsEmptyView? = {
        guard let view = UIView.loadFromNib(named: String(describing: ASCDocumentsEmptyView.self)) as? ASCDocumentsEmptyView else { return nil }
        return view
    }()

    private lazy var categoryIsRecent: Bool = {
        guard let onlyOfficeProvider = provider as? ASCOnlyofficeProvider else { return false }
        return onlyOfficeProvider.category?.folder?.rootFolderType == .onlyofficeRecent
    }()
    
    private lazy var categoryIsFavorite: Bool = {
        guard let onlyOfficeProvider = provider as? ASCOnlyofficeProvider else { return false }
        return onlyOfficeProvider.category?.folder?.rootFolderType == .onlyofficeFavorites
    }()
    
    private lazy var sharedVC = ASCSharingOptionsViewController(style: .grouped)
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        definesPresentationContext = true
       
        tableView.backgroundView = UIView()
        tableView.tableFooterView = UIView()

        configureNavigationBar(animated: false)
        configureProvider()
        configureSwipeGesture()
        
        let addObserver: (Notification.Name, Selector) -> Void = { name, selector in
            NotificationCenter.default.addObserver(
                self,
                selector: selector,
                name: name,
                object: nil
            )
        }

        addObserver(ASCConstants.Notifications.updateFileInfo, #selector(updateFileInfo(_:)))
        addObserver(ASCConstants.Notifications.networkStatusChanged, #selector(networkStatusChanged(_:)))
        addObserver(ASCConstants.Notifications.updateSizeClass, #selector(onUpdateSizeClass(_:)))
        addObserver(ASCConstants.Notifications.openLocalFileByUrl, #selector(onOpenLocalFileByUrl(_:)))
        addObserver(ASCConstants.Notifications.appDidBecomeActive, #selector(onAppDidBecomeActive(_:)))
        addObserver(ASCConstants.Notifications.reloadData, #selector(onReloadData(_:)))
        addObserver(UIApplication.willResignActiveNotification, #selector(onAppMovedToBackground))
        
        UserDefaults.standard.addObserver(self, forKeyPath: ASCConstants.SettingsKeys.sortDocuments, options: [.new], context: nil)

        // Drag Drop support
        if #available(iOS 11.0, *) {
            tableView.dragDelegate = self
            tableView.dropDelegate = self
            tableView.dragInteractionEnabled = true
            tableView.separatorStyle = .none
        }
        
        if !featureLargeTitle {
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.searchController = searchController
        }
        
    }

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: ASCConstants.SettingsKeys.sortDocuments)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !featureLargeTitle {
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.searchController = searchController
        }
        
        if UIDevice.phone, let navigationController = navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationItem.leftBarButtonItem = nil
            }
        }

        showToolBar(tableView.isEditing)

        ASCViewControllerManager.shared.rootController?.tabBar.isHidden = tableView.isEditing
        updateLargeTitlesSize()
        
        if folder?.parent == nil {
            splitViewController?.presentsWithGesture = true
            let gesture = view.gestureRecognizers?.filter { $0.name == "swipeRight" }
            gesture?.first?.isEnabled = false
        } else {
            splitViewController?.presentsWithGesture = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = uiRefreshControl
        } else {
            tableView.addSubview(uiRefreshControl)
        }
        
        checkUnsuccessfullyOpenedFile()
        configureProvider()

        // Update current provider if needed
        if let provider = provider, provider.id != ASCFileManager.provider?.id {
            ASCFileManager.provider = provider
        }

        // Store last open folder
        if let folder = folder, let folderAsString = folder.toJSONString() {
            UserDefaults.standard.set(folderAsString, forKey: ASCConstants.SettingsKeys.lastFolder)
        }

        if #available(iOS 11.0, *), featureLargeTitle {
            DispatchQueue.main.async { [weak self] in
                if let searchController = self?.searchController {
                    searchController.searchBar.alpha = 0
                    self?.navigationItem.searchController = searchController

                    UIView.animate(withDuration: 0.3, animations: {
                        searchController.searchBar.alpha = 1
                    })
                }
            }
        }
        
        navigationController?.navigationBar.prefersLargeTitles = tableData.count > 0
        navigationItem.largeTitleDisplayMode = tableData.count > 0 ? .automatic : .never
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if #available(iOS 11.0, *) {
            navigationItem.searchController = nil
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == ASCConstants.SettingsKeys.sortDocuments {
            loadFirstPage()
        }
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait, .landscape]
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return super.preferredInterfaceOrientationForPresentation
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if let viewController = hideableViewControllerOnTransition {
            viewController.dismiss(animated: true, completion: nil)
            hideableViewControllerOnTransition = nil
        }
        
        tableView.visibleCells.forEach { cell in
            if let swipeCell = cell as? MGSwipeTableCell {
                swipeCell.hideSwipe(animated: false)
            }
        }
    }
    
    // MARK: - Public
    
    func reset() {
        ASCFileManager.reset()

        provider?.reset()
        folder = nil
        title = nil
        
        loadingView.removeFromSuperview()
        emptyView?.removeFromSuperview()

        tableView.reloadData()
    }
    
    @objc func refresh(_ refreshControl: UIRefreshControl) {
        if searchController.isActive {
            refreshControl.endRefreshing()
            return
        }

        provider?.page = 0
        
        fetchData({ [weak self] success in
            DispatchQueue.main.async {
                refreshControl.endRefreshing()
                
                guard let strongSelf = self else { return }

                strongSelf.showErrorView(!success)

                if success {
                    strongSelf.showEmptyView(strongSelf.total < 1)
                }

                strongSelf.updateNavBar()
            }
        })
    }
    
//    @objc func handleLongPress(longPressGesture: UILongPressGestureRecognizer) {
//        let point = longPressGesture.location(in: tableView)
//
//        if let indexPath = tableView.indexPathForRow(at: point) {
//            if (longPressGesture.state == .began) {
//                setEditMode(true)
//
//                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
//                tableView(tableView, didSelectRowAt: indexPath)
//            }
//        }
//    }

    func add(entity: Any, open: Bool = true) {
        guard let provider = provider else { return }
        
        if let file = entity as? ASCFile {
            provider.add(item: file, at: 0)
            
            provider.updateSort { provider, currentFolder, success, error in
                self.tableView.reloadData()
                self.showEmptyView(self.total < 1)
                
                if let index = self.tableData.firstIndex(where: { $0.id == file.id }) {
                    if ASCConstants.Feature.hideSearchbarIfEmpty {
                        self.searchController.searchBar.isHidden = false
                    }
                    self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
                    self.tableView.setNeedsLayout()
                    
                    delay(seconds: 0.3) { [weak self] in
                        if let newCell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
                            self?.highlight(cell: newCell)
                        }
                    }
                }
            }
            
            if open {
                let title = file.title
                let fileExt = title.fileExtension().lowercased()
                let isDocument = fileExt == "docx"
                let isSpreadsheet = fileExt == "xlsx"
                let isPresentation = fileExt == "pptx"
                
                if isDocument || isSpreadsheet || isPresentation {
                    provider.open(file: file, viewMode: false)
                }
            }
        } else if let folder = entity as? ASCFolder {
            provider.add(item: folder, at: 0)
            
            provider.updateSort { provider, currentFolder, success, error in
                self.tableView.reloadData()

                self.showEmptyView(self.total < 1)
                
                if let index = self.tableData.firstIndex(where: { $0.uid == folder.uid }) {
                    if ASCConstants.Feature.hideSearchbarIfEmpty {
                        self.searchController.searchBar.isHidden = false
                    }
                    
                    self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
                    self.tableView.setNeedsLayout()
                    
                    delay(seconds: 0.3) { [weak self] in
                        if let newCell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
                            self?.highlight(cell: newCell)
                        }
                    }
                }
            }
        }

        updateNavBar()
        showEmptyView(false)
        showErrorView(false)
    }
    
    func highlight(entity: ASCEntity?) {
        highlightEntity = entity
        
        if let searchEntity = highlightEntity {
            if tableData.count > 0 {
                highlightEntity = nil
                
                if let index = tableData.firstIndex(where: { $0.uid == searchEntity.uid }) {
                    tableView.scrollToRow(at: IndexPath(item: index, section: 0), at: .middle, animated: false)
                    
                    if let cell = tableView.cellForRow(at: IndexPath(item: index, section: 0)) {
                        highlight(cell: cell)
                    }
                }
            }
        }
    }
    
    fileprivate func flashBlockInteration() {
        view.isUserInteractionEnabled = false
        ASCViewControllerManager.shared.rootController?.isUserInteractionEnabled = false
        delay(seconds: 0.2) {
            self.view.isUserInteractionEnabled = true
            ASCViewControllerManager.shared.rootController?.isUserInteractionEnabled = true
        }
    }
    
    @objc func onAddEntityAction() {
        guard let provider = provider else { return }
        flashBlockInteration()
        ASCCreateEntity().showCreateController(for: provider, in: self, sender: addBarButton)
    }
    
    @objc func onSortSelectAction(_ sender: Any) {
        if #available(iOS 14.0, *) {
            if let button = sender as? UIButton {
                button.showsMenuAsPrimaryAction = true
                button.menu = sortSelectMenu(for: button)
            }
        } else {
            let moreController = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .actionSheet,
                tintColor: nil
            )
            
            moreController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Select", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] (action) in
                        self.setEditMode(!self.tableView.isEditing)
                    })
            )
            
            moreController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Sort", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] (action) in
                        self.onSortAction()
                    })
            )
            
            moreController.addAction(
                UIAlertAction(
                    title: ASCLocalization.Common.cancel,
                    style: .cancel,
                    handler: nil)
            )
            
            present(moreController, animated: true, completion: nil)
        }
    }
    
    
    
    @objc func onCancelAction() {
        setEditMode(false)
    }
    
    @objc func onSortAction() {
        var sortType: ASCDocumentSortType = .dateandtime
        var sortAscending = false
        var sortStates: [ASCDocumentSortStateType] = defaultsSortTypes.map { ($0, $0 == sortType) }
        
        if let sortInfo = UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any] {
            if let sortBy = sortInfo["type"] as? String, !sortBy.isEmpty {
                sortType = ASCDocumentSortType(sortBy)
                sortStates = defaultsSortTypes.map { ($0, $0 == sortType) }
            }

            if let sortOrder = sortInfo["order"] as? String, !sortOrder.isEmpty {
                sortAscending = sortOrder == "ascending"
            }
        }

        if ![.deviceDocuments, .deviceTrash].contains(folder?.rootFolderType) {
            sortStates.append((.author, sortType == .author))
        }
        
        navigator.navigate(to: .sort(types: sortStates, ascending: sortAscending, complation: { type, ascending in
            if (sortType != type) || (ascending != sortAscending) {
                let sortInfo = [
                    "type": type.rawValue,
                    "order": ascending ? "ascending" : "descending"
                ]

                UserDefaults.standard.set(sortInfo, forKey: ASCConstants.SettingsKeys.sortDocuments)
            }
        }))
    }
    
    @objc func onSelectAction() {
        guard view.isUserInteractionEnabled else { return }
        setEditMode(true)
        flashBlockInteration()
    }
    
    @objc func popViewController(gesture: UISwipeGestureRecognizer) -> Void {
        if gesture.direction == .right {
        navigationController?.popViewController(animated: true)
       }
    }
    
    // MARK: - Private

    private func configureProvider() {
        guard let provider = provider else { return }
        
        if provider is ASCiCloudProvider {
            tableView.refreshControl = nil
        }
    }
    
    private func configureNavigationBar(animated: Bool = true) {

        addBarButton = addBarButton
            ?? createAddBarButton()
        sortSelectBarButton = sortSelectBarButton
            ?? createSortSelectBarButton()
        sortBarButton = sortBarButton
            ?? createSortBarButton()
        selectBarButton = selectBarButton
            ?? ASCStyles.createBarButton(image: Asset.Images.navSelect.image, target: self, action: #selector(onSelectAction))
        cancelBarButton = cancelBarButton
            ?? ASCStyles.createBarButton(title: ASCLocalization.Common.cancel, target: self, action: #selector(onCancelAction))
        selectAllBarButton = selectAllBarButton
            ?? ASCStyles.createBarButton(title: NSLocalizedString("Select", comment: "Button title"), target: self, action: #selector(onSelectAll))
        
        sortSelectBarButton?.isEnabled = total > 0
        sortBarButton?.isEnabled = total > 0
        selectBarButton?.isEnabled = total > 0
        selectAllBarButton?.isEnabled = total > 0
        
        if #available(iOS 14.0, *) {
            for barButton in [sortSelectBarButton, sortBarButton] {
                if let button = barButton?.customView as? UIButton {
                    button.showsMenuAsPrimaryAction = true
                    button.menu = sortSelectMenu(for: button)
                }
            }
            
            selectAllBarButton = ASCStyles.createBarButton(title: NSLocalizedString("Select", comment: "Button title"), menu: selectAllMenu())
        }

        if tableView.isEditing {
            navigationItem.setLeftBarButtonItems([selectAllBarButton!], animated: animated)
            navigationItem.setRightBarButtonItems([cancelBarButton!], animated: animated)
        } else {
            navigationItem.setLeftBarButtonItems(nil, animated: animated)
            var rightBarBtnItems = [ASCStyles.barFixedSpace]
            if let addBarBtn = addBarButton {
                rightBarBtnItems.append(addBarBtn)
            }
            if UIDevice.phone {
                if let sortSelectBarBtn = sortSelectBarButton {
                    rightBarBtnItems.append(sortSelectBarBtn)
                }
            } else {
                if let sortBarBtn = sortBarButton {
                    rightBarBtnItems.append(sortBarBtn)
                }
                if let selectBarBtn = selectBarButton {
                    rightBarBtnItems.append(selectBarBtn)
                }
            }
            navigationItem.setRightBarButtonItems(rightBarBtnItems, animated: animated)
        }

        if #available(iOS 11.0, *), featureLargeTitle {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .automatic
        }
    }
    
    private func createAddBarButton() -> UIBarButtonItem? {
        let showAddButton = provider?.allowEdit(entity: folder) ?? false
        
        guard showAddButton else { return nil }
        
        return ASCStyles.createBarButton(image: Asset.Images.navAdd.image, target: self, action:#selector(onAddEntityAction))
    }
    
    private func createSortSelectBarButton() -> UIBarButtonItem {
        guard categoryIsRecent else {
            return ASCStyles.createBarButton(image: Asset.Images.navMore.image, target: self, action: #selector(onSortSelectAction))
        }
        
        return ASCStyles.createBarButton(title: NSLocalizedString("Select", comment: "Navigation bar button title"), target: self, action: #selector(onSelectAction))
    }
    
    private func createSortBarButton() -> UIBarButtonItem? {
        guard !categoryIsRecent else {
            return nil
        }
        
        return ASCStyles.createBarButton(image: Asset.Images.navSort.image, target: self, action: #selector(onSortAction))
    }

    private func configureToolBar() {
        guard let folder = folder else {
            return
        }
        
        let isRoot = folder.parentId == nil || folder.parentId == "0"
        let isDevice = (provider?.id == ASCFileManager.localProvider.id)
        let isShared = folder.rootFolderType == .onlyofficeShare
        let isTrash = self.isTrash(folder)
        let isProjectRoot = (folder.rootFolderType == .onlyofficeBunch || folder.rootFolderType == .onlyofficeProjects) && isRoot
        let isGuest = ASCFileManager.onlyofficeProvider?.user?.isVisitor ?? false
        
        self.events.removeListeners(eventNameToRemoveOrNil: "item:didSelect")
        self.events.removeListeners(eventNameToRemoveOrNil: "item:didDeselect")
        
        let barFlexSpacer: UIBarButtonItem = {
            return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        }()

        let createBarButton: (_ image: UIImage, _ selector: Selector) -> UIBarButtonItem = { [weak self] image, selector in
            guard let strongSelf = self else { return UIBarButtonItem() }
            let buttonItem = ASCStyles.createBarButton(image:image, target:strongSelf, action:selector)
            
            buttonItem.isEnabled = (strongSelf.tableView.indexPathsForSelectedRows?.count ?? 0) > 0
            
            strongSelf.events.listenTo(eventName: "item:didSelect") { [weak self] in
                buttonItem.isEnabled = (self?.tableView.indexPathsForSelectedRows?.count ?? 0) > 0
            }
            strongSelf.events.listenTo(eventName: "item:didDeselect") { [weak self] in
                buttonItem.isEnabled = (self?.tableView.indexPathsForSelectedRows?.count ?? 0) > 0
            }
            
            return buttonItem
        }
        
        var items: [UIBarButtonItem] = []

        // Select
//        items.append(ASCStyles.createBarButton(title: NSLocalizedString("Select", comment: ""), target: self, action: #selector(onSelectAll)))
//        items.append(ASCStyles.createBarButton(image:UIImage(named: "bar-select")!, target:self, action:#selector(onSelectAll)))
//        items.append(barFlexSpacer)

        // Move
        if !isTrash && (isDevice || !(isShared || isProjectRoot || isGuest)) {
            items.append(createBarButton(Asset.Images.barMove.image, #selector(onMoveSelected)))
            items.append(barFlexSpacer)
        }
        
        // Copy
        if !isTrash {
            items.append(createBarButton(Asset.Images.barCopy.image, #selector(onCopySelected)))
            items.append(barFlexSpacer)
        }
        
        // Restore
        if isTrash {
            items.append(createBarButton(Asset.Images.barRecover.image, #selector(onMoveSelected)))
            items.append(barFlexSpacer)
        }
        
        // Remove from list
        if isShared {
            items.append(createBarButton(Asset.Images.barDeleteLink.image, #selector(onTrashSelected)))
            items.append(barFlexSpacer)
        }
        
        // Remove
        if isDevice || !(isShared || isProjectRoot || isGuest) {
            items.append(createBarButton(Asset.Images.barDelete.image, #selector(onTrashSelected)))
            items.append(barFlexSpacer)
        }
        
        // Remove all
        if isTrash {
            items.append(UIBarButtonItem(image: Asset.Images.barDeleteAll.image, style: .plain, target: self, action: #selector(onEmptyTrashSelected)))
            items.append(barFlexSpacer)
        }
        
        if items.count > 1 {
           items.removeLast()
        }

        self.events.listenTo(eventName: "item:didSelect") { [weak self] in
            self?.updateSelectedInfo()
        }
        self.events.listenTo(eventName: "item:didDeselect") { [weak self] in
            self?.updateSelectedInfo()
        }
        
        setToolbarItems(items, animated: false)
    }

    private func updateSelectedInfo() {
        let fileCount = tableData
            .filter{ $0 is ASCFile }
            .filter{ selectedIds.contains($0.uid) }
            .count
        let folderCount = tableData
            .filter{ $0 is ASCFolder }
            .filter{ selectedIds.contains($0.uid) }
            .count

        if fileCount + folderCount > 0 {
            if UIDevice.phone {
                title = String(format: NSLocalizedString("Selected: %ld", comment: ""), fileCount + folderCount)
            } else {
                if folderCount > 0 && fileCount > 0 {
                    title = String.localizedStringWithFormat(NSLocalizedString("%lu Folder and %lu File selected", comment:""), folderCount, fileCount)
                } else if folderCount > 0 {
                    title = String.localizedStringWithFormat(NSLocalizedString("%lu Folder selected", comment:""), folderCount)
                } else if fileCount > 0 {
                    title = String.localizedStringWithFormat(NSLocalizedString("%lu File selected", comment:""), fileCount)
                } else {
                    title = folder?.title
                }
            }
        } else {
            title = folder?.title
        }
    }

    private func updateTitle() {
        if !tableView.isEditing {
            title = folder?.title
        } else {
            updateSelectedInfo()
        }
    }

    private func showToolBar(_ show: Bool, animated: Bool = true) {
        navigationController?.setToolbarHidden(!show, animated: animated)
    }
    
    private func setEditMode(_ edit: Bool) {
        ASCViewControllerManager.shared.rootController?.tabBar.isHidden = edit

        tableView.setEditing(edit, animated: true)
        configureNavigationBar()
        
        configureToolBar()
        showToolBar(edit)
        
        selectedIds.removeAll()
        updateTitle()
    }
    
    private func fetchData(_ completeon: ((Bool) -> Void)? = nil) {
        guard let provider = provider else {
            completeon?(false)
            return
        }

        updateTitle()

        if provider.id == ASCFileManager.localProvider.id {
            fetchLocalData(completeon)
        } else {
            fetchCloudData(completeon)
        }
    }

    private func fetchLocalData(_ completeon: ((Bool) -> ())? = nil) {
        guard let folder = folder, provider?.id == ASCFileManager.localProvider.id else {
            completeon?(false)
            return
        }

        var params: [String: Any] = [:]

        // Sort
        if let sortInfo = UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any] {
            var sortParams: [String: Any] = [:]

            if let sortBy = sortInfo["type"] as? String, !sortBy.isEmpty {
                sortParams["type"] = sortBy
            }

            if let sortOrder = sortInfo["order"] as? String, !sortOrder.isEmpty {
                sortParams["order"] = sortOrder
            }

            params["sort"] = sortParams
        }

        // Search
        if searchController.isActive, let searchValue = searchValue {
            params["search"] = [
                "text": searchValue
            ]
        }

        provider?.fetch(for: folder, parameters: params) { [weak self] provider, folder, success, error in
            guard let strongSelf = self else { return }

//            strongSelf.total        = provider.total
//            strongSelf.tableData    = provider.items
            strongSelf.tableView.reloadData()

            strongSelf.showEmptyView(strongSelf.total < 1)

            completeon?(true)
        }
    }

    private func fetchCloudData(_ completeon: ((Bool) -> ())? = nil) {
        guard let folder = folder else {
            completeon?(false)
            return
        }

        if let cloudProvider = provider {
            var params: [String: Any] = [:]

            // Search
            if searchController.isActive, let searchValue = searchValue {
                params["search"] = [
                    "text": searchValue
                ]
            }

            // Sort
            if let sortInfo = UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any] {
                var sortParams: [String: Any] = [:]

                if let sortBy = sortInfo["type"] as? String, !sortBy.isEmpty {
                    sortParams["type"] = sortBy
                }

                if let sortOrder = sortInfo["order"] as? String, !sortOrder.isEmpty {
                    sortParams["order"] = sortOrder
                }

                params["sort"] = sortParams
            }

            cloudProvider.fetch(for: folder, parameters: params) { [weak self] provider, entity, success, error in
                guard
                    let strongSelf = self,
                    let folder = entity as? ASCFolder
                else { return }

                let isCanceled = (error as NSError?)?.code == NSURLErrorCancelled

                if !isCanceled {
                    strongSelf.showErrorView(!success, error)
                }

                if success || isCanceled {
                    strongSelf.folder       = folder
//                    strongSelf.total        = provider.total
//                    strongSelf.tableData    = provider.items
                    strongSelf.tableView.reloadData()
                    
                    strongSelf.showEmptyView(strongSelf.total < 1)
                } else {
                    if !provider.handleNetworkError(error) {
                        ASCBanner.shared.showError(
                            title: ASCLocalization.Error.unknownTitle,
                            message: error?.localizedDescription ?? NSLocalizedString("Check your internet connection", comment: "")
                        )
                    }
                }

                completeon?(success)
            }
        }
    }

    private func loadFirstPage(_ completeon: ((_ success: Bool) -> Void)? = nil) {
        provider?.page = 0

        setEditMode(false)
        showLoadingPage(true)
        
        if searchController.isActive {
            searchController.isActive = false
        }
        
        if ASCConstants.Feature.hideSearchbarIfEmpty {
            searchController.searchBar.isHidden = true
        }

        addBarButton?.isEnabled = false // Disable create entity while loading first page

        fetchData({ [weak self] success in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                
                // UI update
                strongSelf.showLoadingPage(false)

                if success {
                    strongSelf.showEmptyView(strongSelf.total < 1)
                } else {
                    if strongSelf.errorView?.superview == nil {
                        strongSelf.showErrorView(true)
                    }
                }

                strongSelf.updateNavBar()
                
                // Fire callback
                completeon?(success)
                
                // Highlight entity if needed
                strongSelf.highlight(entity: strongSelf.highlightEntity)
                
                // Check network
                if !success && strongSelf.folder?.rootFolderType != .deviceDocuments && !ASCNetworkReachability.shared.isReachable && ASCOnlyOfficeApi.shared.token != nil {
                    ASCBanner.shared.showError(
                        title: NSLocalizedString("No network", comment: ""),
                        message: NSLocalizedString("Check your internet connection", comment: "")
                    )
                }
            }
        })
    }
    
    private func showLoadingPage(_ show: Bool) {
        if show {
            if total > 0 {
                return
            }

            showErrorView(false)
            showEmptyView(false)
            
            view.addSubview(loadingView)

            loadingView.translatesAutoresizingMaskIntoConstraints = false
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80).isActive = true
            
//            tableView.isUserInteractionEnabled = false
        } else {
            loadingView.removeFromSuperview()
//            tableView.isUserInteractionEnabled = true
        }
    }
    
    private func showEmptyView(_ show: Bool) {
        if ASCConstants.Feature.hideSearchbarIfEmpty {
            if !searchController.isActive {
                searchController.searchBar.isHidden = show
            }
        }

        if !show {
            emptyView?.removeFromSuperview()
            searchEmptyView?.removeFromSuperview()

            if let tableView = view as? UITableView {
                tableView.backgroundView = nil
            }
            
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .automatic
            
        } else {
            
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            
            let localEmptyView = searchController.isActive ? searchEmptyView : emptyView

            // If loading view still display
            if let _ = loadingView.superview {
                return
            }

            if searchController.isActive {
                localEmptyView?.type = .search
            } else {
                if let folder = folder, let provider = provider {
                    if folder.rootFolderType == .deviceTrash || folder.rootFolderType == .onlyofficeTrash {
                        localEmptyView?.type = .trash
                    } else if provider.type == .local {
                        localEmptyView?.type = .local
                    } else {
                        localEmptyView?.type = .cloud

                        if !(provider.allowEdit(entity: folder)) {
                            localEmptyView?.type = .cloudNoPermissions
                        }
                    }
                }
            }

            if localEmptyView?.superview == nil {
                localEmptyView?.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: tableView.width,
                    height: tableView.height
                )
                if let tableView = view as? UITableView {
                    tableView.backgroundView = localEmptyView
                }
            }
        }
    }

    private func showErrorView(_ show: Bool, _ error: Error? = nil) {
        if !show {
            errorView?.removeFromSuperview()

            if let tableView = view as? UITableView {
                tableView.backgroundView = nil
            }
        } else if tableData.count < 1 {
            showLoadingPage(false)
            showEmptyView(false)

            if !ASCNetworkReachability.shared.isReachable {
                errorView?.type = .networkError
            } else {
                errorView?.type = .error
            }

            if let error = error {
                errorView?.subtitleLabel?.text = "\(errorView?.subtitleLabel?.text ?? "") (\(error.localizedDescription))"
            }

            if errorView?.superview == nil {
                errorView?.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: tableView.frame.width,
                    height: tableView.frame.height
                )
                if let tableView = view as? UITableView {
                    tableView.backgroundView = errorView
                }
            }
        }
    }

    @objc func updateFileInfo(_ notification: Notification) {
        if let file = notification.object as? ASCFile {
            if let path = indexPath(by: file) {
                
                if let index = provider?.items.firstIndex(where: { ($0 as? ASCFile)?.id == file.id } ) {
                    provider?.items[index] = file
                }
                
                tableView.reloadSections(IndexSet(integer: 0), with: .fade)

                delay(seconds: 0.3) { [weak self] in
                    if let cell = self?.tableView.cellForRow(at: path) {
                        self?.highlight(cell: cell)
                    }
                }
            }
        }
    }
    
    @objc func networkStatusChanged(_ notification: Notification) {
        if let info = notification.userInfo {
            log.info(info)
        }
    }
    
    @objc func onUpdateSizeClass(_ notification: Notification) {
        updateTitle()

        // Force hide create popover
        SwiftMessages.hide()

        if  let topVC = ASCViewControllerManager.shared.rootController?.topMostViewController(),
            let _ = topVC.view as? ASCCreateEntityView
        {
            topVC.dismiss(animated: false, completion: nil)
        }

        // Cancel search
        searchController.searchBar.resignFirstResponder()
        searchController.isActive = false

    }
    
    @objc func onOpenLocalFileByUrl(_ notification: Notification) {
        guard
            let folder = folder,
            let userInfo = notification.userInfo,
            let url = userInfo["url"] as? URL
        else {
            return
        }
        
        if !folder.device {
            ASCViewControllerManager.shared.rootController?.display(provider: ASCFileManager.localProvider, folder: nil)
        }

        let fileTitle = url.lastPathComponent
        let filePath = Path(url.path)

        if  let splitVC = ASCViewControllerManager.shared.rootController?.topMostViewController() as? ASCDeviceSplitViewController,
            let documentsNC = splitVC.viewControllers.last as? ASCBaseNavigationController,
            let documentsVC = documentsNC.topViewController as? ASCDocumentsViewController,
            let newFilePath = ASCLocalFileHelper.shared.resolve(filePath: Path.userDocuments + fileTitle)
        {
            if let error = ASCLocalFileHelper.shared.copy(from: filePath, to: newFilePath) {
                log.error("Can not import the file. \(error)")
            } else {
                if filePath.isChildOfPath(Path.userDocuments + "Inbox") {
                    ASCLocalFileHelper.shared.removeFile(filePath)
                }

                let owner = ASCUser()
                owner.displayName = UIDevice.displayName

                let file = ASCFile()
                file.id = newFilePath.rawValue
                file.rootFolderType = .deviceDocuments
                file.title = newFilePath.fileName
                file.created = newFilePath.creationDate
                file.updated = newFilePath.modificationDate
                file.createdBy = owner
                file.updatedBy = owner
                file.device = true
                file.parent = documentsVC.folder
                file.displayContentLength = String.fileSizeToString(with: newFilePath.fileSize ?? 0)
                file.pureContentLength = Int(newFilePath.fileSize ?? 0)

                documentsVC.add(entity: file)
                documentsVC.open(file: file)
            }
        }
    }
    
    @objc func onAppDidBecomeActive(_ notification: Notification) {
        guard let folder = folder else {
            return
        }
        
        if folder.device {
            fetchLocalData()
        }
    }
    
    @objc func onReloadData(_ notification: Notification) {
        tableView.reloadData()
    }
    
    @objc func onAppMovedToBackground() {
        if !(UIDevice.phone || ASCViewControllerManager.shared.currentSizeClass == .compact) {
            setEditMode(false)
        }
    }
    
    private func updateNavBar() {
        let hasError = errorView?.superview != nil

        addBarButton?.isEnabled = !hasError && provider?.allowEdit(entity: folder) ?? false
        sortSelectBarButton?.isEnabled = !hasError && total > 0
        sortBarButton?.isEnabled = !hasError && total > 0
        selectBarButton?.isEnabled = !hasError && total > 0
    }
    
    private func fileMenu(cell: ASCFileCell) -> [MGSwipeButton]? {
        guard
            let file = cell.file,
            let provider = provider,
            view.isUserInteractionEnabled
        else {
            return nil
        }

        let actions = provider.actions(for: file)

        // Restore
        let restore = MGSwipeButton(
            title: NSLocalizedString("Restore", comment: "Button title"),
            icon:  Asset.Images.listMenuRestore.image,
            backgroundColor: ASCConstants.Colors.grey)
        { [unowned self] (cell) -> Bool in
            self.recover(cell: cell)
            return true
        }
        
        // Delete
        let delete = MGSwipeButton(
            title: NSLocalizedString("Delete", comment: "Button title"),
            icon:  Asset.Images.listMenuTrash.image,
            backgroundColor: ASCConstants.Colors.red
        )
        delete.callback = { [unowned self] (cell) -> Bool in
            guard view.isUserInteractionEnabled else { return true }
            
            var title: String? = nil
            let isTrash = self.isTrash(self.folder)

            if isTrash {
                title = NSLocalizedString("The file will be irretrievably deleted. This action is irreversible.", comment: "")
            } else if let folder = self.folder, folder.isThirdParty {
                title = NSLocalizedString("Note: removal from your account can not be undone.", comment: "")
            }
            
            let alertDelete = UIAlertController(
                title: title,
                message: nil,
                preferredStyle: .actionSheet,
                tintColor: nil
            )
            
            alertDelete.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Delete File", comment: "Button title"),
                    style: .destructive,
                    handler: { (action) in
                        cell.hideSwipe(animated: true)
                        self.delete(cell: cell)
                })
            )
            
            if UIDevice.pad {
                alertDelete.modalPresentationStyle = .popover
                alertDelete.popoverPresentationController?.sourceView = delete
                alertDelete.popoverPresentationController?.sourceRect = delete.bounds
                alertDelete.popoverPresentationController?.permittedArrowDirections = [.up, .down]
                flashBlockInteration()
            } else {
                alertDelete.addAction(
                    UIAlertAction(
                        title: ASCLocalization.Common.cancel,
                        style: .cancel,
                        handler: { (action) in
                            cell.hideSwipe(animated: true)
                    })
                )
            }

            self.present(alertDelete, animated: true, completion: nil)
            self.hideableViewControllerOnTransition = alertDelete
            
            return false
        }
        
        // Download
        let download = MGSwipeButton(
            title: NSLocalizedString("Download", comment: "Button title"),
            icon: Asset.Images.listMenuDownload.image,
            backgroundColor: ASCConstants.Colors.grey)
        { [unowned self] (cell) -> Bool in
            self.download(cell: cell)
            return true
        }
        
        // Rename
        let rename = MGSwipeButton(
        title: NSLocalizedString("Rename", comment: "Button title"),
            icon: Asset.Images.listMenuRename.image,
        backgroundColor: ASCConstants.Colors.grey)
        { [unowned self] (cell) -> Bool in
            self.rename(cell: cell)
            return true
        }
        
        // Copy
        let copy = MGSwipeButton(
            title: NSLocalizedString("Copy", comment: "Button title"),
            icon: Asset.Images.listMenuCopy.image,
            backgroundColor: ASCConstants.Colors.grey)
        { [unowned self] (cell) -> Bool in
            self.copy(cell: cell)
            return true
        }
        
        // More
        let more = MGSwipeButton(
            title: NSLocalizedString("More", comment: "Button title"),
            icon: Asset.Images.listMenuMore.image,
            backgroundColor: ASCConstants.Colors.lightGrey
        )
        more.callback = { [unowned self] (swipedCell) -> Bool in
            guard view.isUserInteractionEnabled else { return true }
            
            if let moreAlertController = self.fileActionMenu(cell: cell) {
                if UIDevice.pad {
                    moreAlertController.modalPresentationStyle = .popover
                    moreAlertController.popoverPresentationController?.sourceView = more
                    moreAlertController.popoverPresentationController?.sourceRect = more.bounds
                    moreAlertController.popoverPresentationController?.permittedArrowDirections = [.up, .down]
                    flashBlockInteration()
                }

                moreAlertController.view.tintColor = self.view.tintColor
                self.searchController.searchBar.resignFirstResponder()
                self.present(moreAlertController, animated: true, completion: nil)
                self.hideableViewControllerOnTransition = moreAlertController
            }

            return false
        }
        
        cell.swipeBackgroundColor = ASCConstants.Colors.lighterGrey

        var items: [MGSwipeButton] = []

        if actions.contains(.delete)    { items.append(delete) }
        if actions.contains(.restore)   { items.append(restore) }
        if actions.contains(.rename)    { items.append(rename) }
        if actions.contains(.copy)      { items.append(copy) }
        if actions.contains(.download)  { items.append(download) }

        if items.count > 2 {
            items = Array(items[..<2])
            items.append(more)
        }

        return decorate(menu: items)
    }
    
    private func folderMenu(cell: ASCFolderCell) -> [MGSwipeButton]? {
        guard
            let folder = cell.folder,
            let provider = provider,
            view.isUserInteractionEnabled
        else {
            return nil
        }

        let actions = provider.actions(for: folder)

        // Restore
        let restore = MGSwipeButton(
            title: NSLocalizedString("Restore", comment: "Button title"),
            icon: Asset.Images.listMenuRestore.image,
            backgroundColor: ASCConstants.Colors.grey)
        { [unowned self] (cell) -> Bool in
            self.recover(cell: cell)
            return true
        }
        
        // Delete
        let delete = MGSwipeButton(
            title: NSLocalizedString("Delete", comment: "Button title"),
            icon: Asset.Images.listMenuTrash.image,
            backgroundColor: ASCConstants.Colors.red
        )
        delete.callback = { [unowned self] (cell) -> Bool in
            guard view.isUserInteractionEnabled else { return true }
            
            var title: String? = nil
            let isTrash = self.isTrash(self.folder)

            if isTrash {
                title = NSLocalizedString("The folder will be irretrievably deleted. This action is irreversible.", comment: "")
            } else if let folder = self.folder, folder.isThirdParty {
                title = NSLocalizedString("Note: removal from your account can not be undone.", comment: "")
            }
            
            let alertDelete = UIAlertController(
                title: title,
                message: nil,
                preferredStyle: .actionSheet,
                tintColor: nil
            )
            
            alertDelete.addAction(
                UIAlertAction(
                    title: folder.isThirdParty && !(self.folder?.isThirdParty ?? false)
                        ? NSLocalizedString("Disconnect third party", comment: "")
                        : NSLocalizedString("Delete Folder", comment: ""),
                    style: .destructive,
                    handler: { (action) in
                        cell.hideSwipe(animated: true)
                        self.delete(cell: cell)
                })
            )
            
            if UIDevice.pad {
                alertDelete.modalPresentationStyle = .popover
                alertDelete.popoverPresentationController?.sourceView = delete
                alertDelete.popoverPresentationController?.sourceRect = delete.bounds
                alertDelete.popoverPresentationController?.permittedArrowDirections = [.up, .down]
                flashBlockInteration()
            } else {
                alertDelete.addAction(
                    UIAlertAction(
                        title: ASCLocalization.Common.cancel,
                        style: .cancel,
                        handler: { (action) in
                            cell.hideSwipe(animated: true)
                    })
                )
            }

            self.present(alertDelete, animated: true, completion: nil)
            self.hideableViewControllerOnTransition = alertDelete
            
            return false
        }
        
        // Rename
        let rename = MGSwipeButton(
            title: NSLocalizedString("Rename", comment: "Button title"),
            icon: Asset.Images.listMenuRename.image,
            backgroundColor: ASCConstants.Colors.grey)
        { [unowned self] (cell) -> Bool in
            self.rename(cell: cell)
            return true
        }
        
        // Copy
        let copy = MGSwipeButton(
            title: NSLocalizedString("Copy", comment: "Button title"),
            icon: Asset.Images.listMenuCopy.image,
            backgroundColor: ASCConstants.Colors.grey)
        { [unowned self] (cell) -> Bool in
            self.copy(cell: cell)
            return true
        }
        
        // More
        let more = MGSwipeButton(
            title: NSLocalizedString("More", comment: "Button title"),
            icon: Asset.Images.listMenuMore.image,
            backgroundColor: ASCConstants.Colors.lightGrey
        )
        more.callback = { [unowned self] (swipedCell) -> Bool in
            guard view.isUserInteractionEnabled else { return true }
            
            if let moreAlertController = self.folderActionMenu(cell: cell) {
                if UIDevice.pad {
                    moreAlertController.modalPresentationStyle = .popover
                    moreAlertController.popoverPresentationController?.sourceView = more
                    moreAlertController.popoverPresentationController?.sourceRect = more.bounds
                    moreAlertController.popoverPresentationController?.permittedArrowDirections = [.up, .down]
                    flashBlockInteration()
                }
                
                moreAlertController.view.tintColor = self.view.tintColor
                self.searchController.searchBar.resignFirstResponder()
                self.present(moreAlertController, animated: true, completion: nil)
                self.hideableViewControllerOnTransition = moreAlertController
            }
            
            return false
        }
        
        cell.swipeBackgroundColor = ASCConstants.Colors.lighterGrey

        var items: [MGSwipeButton] = []

        if actions.contains(.unmount) || actions.contains(.delete) { items.append(delete) }
        if actions.contains(.restore)   { items.append(restore) }
        if actions.contains(.rename)    { items.append(rename) }
        if actions.contains(.copy)      { items.append(copy) }

        if items.count > 2 {
            items = Array(items[..<2])
            items.append(more)
        }

        return decorate(menu: items)
    }

    @available(iOS 13.0, *)
    private func makeFileContextMenu(for cell: ASCFileCell) -> UIMenu? {
        guard
            let file = cell.file,
            let provider = provider
        else {
            return nil
        }
        
        let actions = provider.actions(for: file)

        var rootActions: [UIMenuElement] = []
        var topActions: [UIMenuElement] = []
        var middleActions: [UIMenuElement] = []
        var bottomActions: [UIMenuElement] = []

        /// Preview action

        if actions.contains(.open) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Preview", comment: "Button title"),
                    image: UIImage(systemName: "eye"))
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.open(file: file, viewMode: true)
                }
            )
        }

        /// Edit action

        if actions.contains(.edit) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Edit", comment: "Button title"),
                    image: UIImage(systemName: "pencil"))
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.open(file: file)
                }
            )
        }

        /// Download action

        if actions.contains(.download) {
            topActions.append(
                UIAction(
                    title: NSLocalizedString("Download", comment: "Button title"),
                    image: UIImage(systemName: "square.and.arrow.down"))
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.download(cell: cell)
                }
            )
        }
        
        /// Favorite action

        if actions.contains(.favarite) {
            topActions.append(
                UIAction(
                    title: file.isFavorite
                        ? NSLocalizedString("Remove from Favorites", comment: "Button title")
                        : NSLocalizedString("Mark as favorite", comment: "Button title"),
                    image: file.isFavorite
                        ? UIImage(systemName: "star.fill")
                        : UIImage(systemName: "star"))
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.favorite(cell: cell, favorite: !file.isFavorite)
                }
            )
        }

        /// Rename action

        if actions.contains(.rename) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    image: UIImage(systemName: "pencil.and.ellipsis.rectangle"))
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.rename(cell: cell)
                }
            )
        }

        /// Copy action

        let copy = UIAction(
            title: NSLocalizedString("Copy", comment: "Button title"),
            image: UIImage(systemName: "doc.on.doc"))
        { [unowned self] action in
            cell.hideSwipe(animated: true)
            self.copy(cell: cell)
        }

        /// Duplicate action

        let duplicate = UIAction(
            title: NSLocalizedString("Duplicate", comment: "Button title"),
            image: UIImage(systemName: "plus.rectangle.on.rectangle"))
        { [unowned self] action in
            cell.hideSwipe(animated: true)
            self.duplicate(cell: cell)
        }

        /// Move action

        let move = UIAction(
            title: NSLocalizedString("Move", comment: "Button title"),
            image: UIImage(systemName: "folder"))
        { [unowned self] action in
            cell.hideSwipe(animated: true)
            self.move(cell: cell)
        }

        /// Transfer items

        if actions.contains(.copy), actions.contains(.duplicate), actions.contains(.move) {
            middleActions.append(
                UIMenu(title: NSLocalizedString("Move or Copy", comment: "Button title") + "...", children: [copy, duplicate, move])
            )
        } else {
            if actions.contains(.copy) {
                middleActions.append(copy)
            }
            if actions.contains(.duplicate) {
                middleActions.append(duplicate)
            }
            if actions.contains(.move) {
                middleActions.append(move)
            }
        }
        
        /// Delete action

        if actions.contains(.delete) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive)
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.delete(cell: cell)
                }
            )
        }

        /// Unmount action

        if actions.contains(.unmount) {
            middleActions.append(
                UIAction(
                    title: NSLocalizedString("Disconnect third party", comment: "Button title"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive)
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.delete(cell: cell)
                }
            )
        }

        /// Share action

        if actions.contains(.share) {
            bottomActions.append(
                UIAction(
                    title: NSLocalizedString("Sharing Settings", comment: "Button title"),
                    image: UIImage(systemName: "person.2"))
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    presentShareController(in: self, entity: file)
                }
            )
        }

        /// Export action

        if actions.contains(.export) {
            bottomActions.append(
                UIAction(
                    title: NSLocalizedString("Share", comment: "Button title"),
                    image: UIImage(systemName: "square.and.arrow.up"))
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.export(cell: cell)
                }
            )
        }

        if #available(iOS 14.0, *) {
//            let selectMenu = UIMenu(title: "", options: .displayInline, children: selectActions)
//            let sortMenu = UIMenu(title: "", options: .displayInline, children: sortActions)
//            var menus: [UIMenuElement] = [sortMenu]
            
            return UIMenu(title: "", options: [.displayInline], children: [
                UIMenu(title: "", options: .displayInline, children: topActions),
                UIMenu(title: "", options: .displayInline, children: middleActions),
                UIMenu(title: "", options: .displayInline, children: bottomActions)
            ])
        } else {
            rootActions = [topActions, bottomActions, middleActions].reduce([], +)
            return UIMenu(title: "", children: rootActions)
        }
    }

    @available(iOS 13.0, *)
    private func makeFolderContextMenu(for cell: ASCFolderCell) -> UIMenu? {
        guard
            let folder = cell.folder,
            let provider = provider
        else {
            return nil
        }

        let actions = provider.actions(for: folder)

        var rootActions: [UIMenuElement] = []

        /// Rename action

        if actions.contains(.rename) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    image: UIImage(systemName: "pencil.and.ellipsis.rectangle"))
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.rename(cell: cell)
                }
            )
        }


        /// Copy action

        let copy = UIAction(
            title: NSLocalizedString("Copy", comment: "Button title"),
            image: UIImage(systemName: "doc.on.doc"))
        { [unowned self] action in
            cell.hideSwipe(animated: true)
            self.copy(cell: cell)
        }

        /// Move action

        let move = UIAction(
            title: NSLocalizedString("Move", comment: "Button title"),
            image: UIImage(systemName: "folder"))
        { [unowned self] action in
            cell.hideSwipe(animated: true)
            self.move(cell: cell)
        }

        /// Transfer items

        if actions.contains(.copy), actions.contains(.move) {
            rootActions.append(
                UIMenu(title: NSLocalizedString("Move or Copy", comment: "Button title") + "...", children: [copy, move])
            )
        } else {
            if actions.contains(.copy) {
                rootActions.append(copy)
            }
            if actions.contains(.move) {
                rootActions.append(move)
            }
        }

        /// Share action

        if actions.contains(.share) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Sharing Settings", comment: "Button title"),
                    image: UIImage(systemName: "person.2"))
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    presentShareController(in: self, entity: folder)
                }
            )
        }


        /// Delete action

        if actions.contains(.delete) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive)
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.delete(cell: cell)
                }
            )
        }

        /// Unmount action

        if actions.contains(.unmount) && !(self.folder?.isThirdParty ?? false) {
            rootActions.append(
                UIAction(
                    title: NSLocalizedString("Disconnect third party", comment: "Button title"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive)
                { [unowned self] action in
                    cell.hideSwipe(animated: true)
                    self.delete(cell: cell)
                }
            )
        }

        return UIMenu(title: "", children: rootActions)
    }
    
    @available(iOS 14.0, *)
    private func sortSelectMenu(for button: UIButton) -> UIMenu? {
        var selectActions: [UIMenuElement] = []
        var sortActions: [UIMenuElement] = []
        
        selectActions.append(
            UIAction(
                title: NSLocalizedString("Select", comment: "Button title"),
                image: UIImage(systemName: "checkmark.circle"))
            { action in
                self.setEditMode(!self.tableView.isEditing)
            }
        )
        
        var sortType: ASCDocumentSortType = .dateandtime
        var sortAscending = false

        if let sortInfo = UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any] {
            if let sortBy = sortInfo["type"] as? String, !sortBy.isEmpty {
                sortType = ASCDocumentSortType(sortBy)
            }

            if let sortOrder = sortInfo["order"] as? String, !sortOrder.isEmpty {
                sortAscending = sortOrder == "ascending"
            }
        }

        var sortStates: [ASCDocumentSortStateType] = defaultsSortTypes.map { ($0, $0 == sortType) }
        
        if ![.deviceDocuments, .deviceTrash].contains(folder?.rootFolderType) {
            sortStates.append((.author, sortType == .author))
        }

        for sort in sortStates {
            sortActions.append(
                UIAction(
                    title: sort.type.description,
                    image: sort.active ? (sortAscending ? UIImage(systemName: "chevron.up") : UIImage(systemName: "chevron.down")) : nil,
                    state: sort.active ? .on : .off)
                { [weak self] action in
                    var sortInfo = [
                        "type": sortType.rawValue,
                        "order": sortAscending ? "ascending" : "descending"
                    ]
                    
                    if sortType != sort.type {
                        sortInfo["type"] = sort.type.rawValue
                    } else {
                        sortAscending = !sortAscending
                        sortInfo["order"] = sortAscending ? "ascending" : "descending"
                    }
                    
                    UserDefaults.standard.set(sortInfo, forKey: ASCConstants.SettingsKeys.sortDocuments)

                    button.menu = self?.sortSelectMenu(for: button)
                }
            )
        }
        
        let selectMenu = UIMenu(title: "", options: .displayInline, children: selectActions)
        let sortMenu = UIMenu(title: "", options: .displayInline, children: sortActions)
        var menus: [UIMenuElement] = [sortMenu]
        
        if UIDevice.phone {
            menus.insert(selectMenu, at: 0)
        }
        
        return UIMenu(title: "", options: [.displayInline], children: menus)
    }
    
    @available(iOS 14.0, *)
    private func selectAllMenu() -> UIMenu? {
        return UIMenu(title: "", options: .displayInline, children: [
            UIAction(
                title: NSLocalizedString("All", comment: ""),
                image: UIImage(systemName: "checkmark.circle"),
                handler: { [weak self] action in
                self?.selectAllItems(type: AnyObject.self)
            }),
            UIAction(
                title: NSLocalizedString("Files", comment: ""),
                image: UIImage(systemName: "doc"),
                handler: { [weak self] action in
                self?.selectAllItems(type: ASCFile.self)
            }),
            UIAction(
                title: NSLocalizedString("Folders", comment: ""),
                image: UIImage(systemName: "folder"),
                handler: { [weak self] action in
                self?.selectAllItems(type: ASCFolder.self)
            }),
            UIAction(
                title: NSLocalizedString("Documents", comment: ""),
                image: UIImage(systemName: "doc.text"),
                handler: { [weak self] action in
                self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.documents)
            }),
            UIAction(
                title: NSLocalizedString("Spreadsheets", comment: ""),
                image: UIImage(systemName: "tablecells"),
                handler: { [weak self] action in
                self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.spreadsheets)
            }),
            UIAction(
                title: NSLocalizedString("Presentations", comment: ""),
                image: UIImage(systemName: "play.rectangle"),
                handler: { [weak self] action in
                self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.presentations)
            }),
            UIAction(
                title: NSLocalizedString("Images", comment: ""),
                image: UIImage(systemName: "photo"),
                handler: { [weak self] action in
                self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.images)
            })
        ])
    }
    
    private func fileActionMenu(cell: ASCFileCell) -> UIAlertController? {
        guard
            let file = cell.file,
            let provider = provider,
            view.isUserInteractionEnabled
        else {
            return nil
        }

        let actions = provider.actions(for: file)

        let actionAlertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )
        
        if actions.contains(.open) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Preview", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.open(file: file, viewMode: true)
                })
            )
        }
        
        if actions.contains(.edit) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Edit", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.open(file: file)
                })
            )
        }
        
//        if actions.contains(.upload) {
//            actionAlertController.addAction(
//                UIAlertAction(
//                    title: NSLocalizedString("Upload", comment: "Button title"),
//                    style: .default,
//                    handler: { [unowned self] action in
//                        cell.hideSwipe(animated: true)
//                        self.upload(cell: cell)
//                })
//            )
//        }

        if actions.contains(.download) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Download", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.download(cell: cell)
                })
            )
        }
        
        if actions.contains(.rename) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.rename(cell: cell)
                })
            )
        }
        
        if actions.contains(.copy) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Copy", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.copy(cell: cell)
                })
            )
        }
        
        if actions.contains(.duplicate) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Duplicate", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                cell.hideSwipe(animated: true)
                self.duplicate(cell: cell)
            }))
        }
        
        if actions.contains(.move) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Move", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.move(cell: cell)
                })
            )
        }

        if actions.contains(.favarite) {
            actionAlertController.addAction(
                UIAlertAction(
                    title:file.isFavorite
                        ? NSLocalizedString("Remove from Favorites", comment: "Button title")
                        : NSLocalizedString("Mark as favorite", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.favorite(cell: cell, favorite: !file.isFavorite)
                })
            )
        }
        
        if actions.contains(.share) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Sharing Settings", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        presentShareController(in: self, entity: file)
                })
            )
        }
        
        if actions.contains(.export) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Share", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.export(cell: cell)
                })
            )
        }
        
        if actions.contains(.delete) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    style: .destructive,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.delete(cell: cell)
                })
            )
        }

        if actions.contains(.unmount) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Disconnect third party", comment: "Button title"),
                    style: .destructive,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.delete(cell: cell)
                })
            )
        }
        
        if UIDevice.phone {
            actionAlertController.addAction(
                UIAlertAction(
                    title: ASCLocalization.Common.cancel,
                    style: .cancel,
                    handler: { (action) in
                        cell.hideSwipe(animated: true)
                })
            )
        }
        
        return actionAlertController
    }
    
    private func folderActionMenu(cell: ASCFolderCell) -> UIAlertController? {
        guard
            let folder = cell.folder,
            let provider = provider,
            view.isUserInteractionEnabled
        else {
            return nil
        }

        let actions = provider.actions(for: folder)

        let actionAlertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )
        
        if actions.contains(.rename) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Rename", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.rename(cell: cell)
                })
            )
        }
        
        if actions.contains(.copy) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Copy", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.copy(cell: cell)
                })
            )
        }
        
        if actions.contains(.move) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Move", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.move(cell: cell)
                })
            )
        }
        
        if actions.contains(.share) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Sharing Settings", comment: "Button title"),
                    style: .default,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        presentShareController(in: self, entity: folder)
                })
            )
        }
        
        if actions.contains(.delete) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    style: .destructive,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.delete(cell: cell)
                })
            )
        }
        
        if actions.contains(.unmount) && !(self.folder?.isThirdParty ?? false) {
            actionAlertController.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Disconnect third party", comment: "Button title"),
                    style: .destructive,
                    handler: { [unowned self] action in
                        cell.hideSwipe(animated: true)
                        self.delete(cell: cell)
                })
            )
        }
        
        if UIDevice.phone {
            actionAlertController.addAction(
                UIAlertAction(
                    title: ASCLocalization.Common.cancel,
                    style: .cancel,
                    handler: { (action) in
                        cell.hideSwipe(animated: true)
                })
            )
        }
        
        return actionAlertController
    }
    
    private func decorate(menu buttons: [MGSwipeButton]) -> [MGSwipeButton] {
        for button in buttons {
            button.buttonWidth = 75
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            button.horizontalCenterIconOverText()
        }
        
        return buttons
    }
    
    private func highlight(cell: UITableViewCell) {
        let originalBgColor = cell.contentView.backgroundColor

        let highlightView = UIView(frame: CGRect(
            x: -100,
            y: 0,
            width: cell.contentView.width + 200,
            height: cell.contentView.height)
        )
        cell.contentView.insertSubview(highlightView, at: 0)

        UIView.animate(withDuration: 0.5, animations: {
            if #available(iOS 13.0, *) {
                highlightView.backgroundColor = .tertiarySystemGroupedBackground
            } else {
                highlightView.backgroundColor = .groupTableViewBackground
            }
        }) { finished in
            UIView.animate(withDuration: 0.5, animations: {
                highlightView.backgroundColor = originalBgColor
            }) { finished in
                highlightView.removeFromSuperview()
            }
        }
    }
    
    private func indexPath(by entity: ASCEntity) -> IndexPath? {
        if let file = entity as? ASCFile {
            if let index = tableData.firstIndex(where: { ($0 as? ASCFile)?.id == file.id } ) {
                return IndexPath(row: index, section: 0)
            }
        } else if let folder = entity as? ASCFolder {
            if let index = tableData.firstIndex(where: { ($0 as? ASCFolder)?.id == folder.id } ) {
                return IndexPath(row: index, section: 0)
            }
        }
        
        return nil
    }

    private func isTrash(_ folder: ASCFolder?) -> Bool {
        return (folder?.rootFolderType == .onlyofficeTrash || folder?.rootFolderType == .deviceTrash)
    }
    
    private func presentShareController(in parent: UIViewController, entity: ASCEntity) {
        //let sharedVC = ASCShareViewController.instantiate(from: Storyboard.share)
        
        let sharedNavigationVC = ASCBaseNavigationController(rootASCViewController: sharedVC)

        if UIDevice.pad {
            sharedNavigationVC.modalPresentationStyle = .formSheet
        }

        sharedNavigationVC.view.tintColor = self.view.tintColor
        
        parent.present(sharedNavigationVC, animated: true, completion: nil)
        sharedVC.setup(entity: entity)
        sharedVC.requestToLoadRightHolders()
    }
    
    private func configureSwipeGesture() {
        let swipeToPreviousFolder = UISwipeGestureRecognizer(target: self, action: #selector(popViewController))
        swipeToPreviousFolder.direction = .right
        swipeToPreviousFolder.name = "swipeRight"
        self.view.addGestureRecognizer(swipeToPreviousFolder)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableData.count < total {
            return tableData.count + 1
        }
        
        return tableData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableData.count > 0 {
            emptyView?.removeFromSuperview()
            
            if indexPath.row < tableData.count {
                if let folder = tableData[indexPath.row] as? ASCFolder {

                    // Folder cell

                    if let folderCell = ASCFolderCell.createForTableView(tableView) as? ASCFolderCell {
                        folderCell.folder = folder
                        folderCell.delegate = self

                        return folderCell
                    }
                } else if let file = tableData[indexPath.row] as? ASCFile {

                    // File cell

                    if let fileCell = ASCFileCell.createForTableView(tableView) as? ASCFileCell {
                        fileCell.provider = provider
                        fileCell.file = file
                        fileCell.delegate = self

                        return fileCell
                    }
                }
            } else {

                // Loader cell

                if let loaderCell = ASCLoaderCell.createForTableView(tableView) as? ASCLoaderCell {
                    loaderCell.tag = kPageLoadingCellTag
                    loaderCell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                    loaderCell.startActivity()

                    return loaderCell
                }
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            if let folder = tableData[indexPath.row] as? ASCFolder {
                selectedIds.insert(folder.uid)
            } else if let file = tableData[indexPath.row] as? ASCFile {
                selectedIds.insert(file.uid)
            }
            
            events.trigger(eventName: "item:didSelect")
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row >= tableData.count {
            return
        }
        
        if let folder = tableData[indexPath.row] as? ASCFolder {
            if isTrash(folder) {
                return
            }
            
            let controller = ASCDocumentsViewController.instantiate(from: Storyboard.main)
            navigationController?.pushViewController(controller, animated: true)

            controller.provider = provider?.copy()
            controller.provider?.reset()
            controller.folder = folder
            controller.title = folder.title
        } else if let file = tableData[indexPath.row] as? ASCFile, let provider = provider {
            open(file: file, viewMode: !provider.allowEdit(entity: file))
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            if let folder = tableData[indexPath.row] as? ASCFolder {
                selectedIds.remove(folder.uid)
            } else if let file = tableData[indexPath.row] as? ASCFile {
                selectedIds.remove(file.uid)
            }
            
            events.trigger(eventName: "item:didDeselect")
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell.tag == kPageLoadingCellTag {
            cell.setEditing(false, animated: false)
            cell.isHidden = false
            provider?.page += 1
            
            fetchData({ [weak self] success in
                if !success {
                    guard let strongSelf = self else { return }
                    
                    strongSelf.provider?.page -= 1
                    delay(seconds: 0.6) {
                        cell.isHidden = true
                    }
                }
            })
        } else {
            if indexPath.row > tableData.count - 1 {
                return
            }

            var isSelected = false
            
            if let folder = tableData[indexPath.row] as? ASCFolder {
                isSelected = selectedIds.contains(folder.uid)
            } else if let file = tableData[indexPath.row] as? ASCFile {
                isSelected = selectedIds.contains(file.uid)
            }
            
            if isSelected {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                self.tableView(tableView, didSelectRowAt: indexPath)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableData.count < total, indexPath.row == tableData.count - 1 {
            if let cell = tableView.cellForRow(at: indexPath), cell.tag == kPageLoadingCellTag {
                return false
            }
        }
        return true
    }

    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
            guard
                let strongSelf = self,
                let cell = tableView.cellForRow(at: indexPath)
            else { return nil }

            if let fileCell = cell as? ASCFileCell {
                return strongSelf.makeFileContextMenu(for: fileCell)
            } else if let folderCell = cell as? ASCFolderCell {
                return strongSelf.makeFolderContextMenu(for: folderCell)
            }

            return nil
        })
    }

    // MARK: - Open files

    func open(file: ASCFile, viewMode: Bool = false) {
        let title           = file.title,
            fileExt         = title.fileExtension().lowercased(),
            allowOpen       = ASCConstants.FileExtensions.allowEdit.contains(fileExt)

        if isTrash(folder) {
            UIAlertController.showWarning(
                in: self,
                message: NSLocalizedString("The file in the Trash can not be viewed.", comment: "")
            )
            return
        }

        if allowOpen {
            provider?.delegate = self
            provider?.open(file: file, viewMode: viewMode)

            searchController.isActive = false
        } else if let index = tableData.firstIndex(where: { $0.id == file.id }) {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
            provider?.delegate = self
            provider?.preview(file: file, files: (tableData.filter { $0 is ASCFile }) as? [ASCFile], in: cell)
        }
    }

    func checkUnsuccessfullyOpenedFile() {
        if let documentInfo = UserDefaults.standard.object(forKey: ASCConstants.SettingsKeys.openedDocument) as? [String : Any] {
            
            if let file = ASCFile(JSONString: documentInfo["file"] as! String) {
                
                if !UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.openedDocumentModifity) {
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocumentModifity)
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                    
                    ASCLocalFileHelper.shared.removeDirectory(Path.userTemporary + file.title)
                    
                    return
                }
                
                // Force reset open recover version
                UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocumentModifity)
              
                let closeHandler = closeProgress(
                    file: file, 
                    title: NSLocalizedString("Saving", comment: "Caption of the processing")
                )
                
                var forceCancel = false
                let progressAlert = ASCProgressAlert(
                    title: NSLocalizedString("Restoring", comment: "Caption of the processing") + "...",
                    message: nil,
                    handler: { (cancel) in
                        forceCancel = cancel
                })
                
                progressAlert.show()
                
                let fullTime = 3.0
                let interval = 0.01
                
                var deadTime = 0.0
                var timer: Timer!
                
                timer = Timer.scheduledTimer(timeInterval: interval, target: BlockOperation(block: { [weak self] in
                    if forceCancel {
                        timer.invalidate()
                        
                        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                        ASCLocalFileHelper.shared.removeDirectory(Path.userTemporary + file.title)
                    } else {
                        
                        deadTime += interval
                        progressAlert.progress = Float(deadTime / fullTime)
                        
                        if deadTime >= fullTime {
                            timer.invalidate()
                            
                            progressAlert.hide(completion: {
                                if file.device {
                                    
                                    let locallyEditing = documentInfo["locallyEditing"] as? Bool ?? false
                                    
                                    if locallyEditing {
                                        // Switch category to 'On Device'
                                        ASCViewControllerManager.shared.rootController?.display(provider: ASCFileManager.localProvider, folder: nil)
                                    } else {
                                        let localeId = file.id.substring(from: Path.userDocuments.rawValue.length)
                                        file.id = (Path.userDocuments + localeId).rawValue
                                    }
                                    
                                    ASCEditorManager.shared.openEditorLocalCopy(
                                        file: file,
                                        viewMode: false,
                                        autosave: true,
                                        locallyEditing: locallyEditing,
                                        handler: nil,
                                        closeHandler: closeHandler
                                    )
                                } else {
//                                    self?.editCloudFile(file, viewMode: false)
                                    self?.provider?.open(file: file, viewMode: false)
                                }
                            })
                        }
                    }
                }), selector: #selector(Operation.main), userInfo: nil, repeats: true)
            }
        }
    }
    
    // MARK: - Entity actions
    
    func delete(cell: UITableViewCell) {
        if let fileCell = cell as? ASCFileCell, let file = fileCell.file {
            delete(indexes: [file.uid])
        } else if let folderCell = cell as? ASCFolderCell, let folder = folderCell.folder {
            delete(indexes: [folder.uid])
        }
    }

    func rename(cell: UITableViewCell) {
        guard let provider = provider else { return }

        var file: ASCFile? = nil
        var folder: ASCFolder? = nil
        
        if let fileCell = cell as? ASCFileCell {
            file = fileCell.file
        } else if let folderCell = cell as? ASCFolderCell {
            folder = folderCell.folder
        }
        
        var hud: MBProgressHUD? = nil
        
        ASCEntityManager.shared.rename(for: provider, entity: file ?? folder) { [unowned self] (status, entity, error) in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.mode = .indeterminate
                hud?.label.text = NSLocalizedString("Renaming", comment: "Caption of the processing")
            } else if status == .error {
                hud?.hide(animated: true)
                
                if error != nil {
                    UIAlertController.showError(in: self, message: error!)
                }
            } else if status == .end {
                if entity != nil {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: 1.3)
                    
                    let file = entity as? ASCFile
                    let folder = entity as? ASCFolder

                    if let indexPath = self.tableView.indexPath(for: cell), let entity: ASCEntity = file ?? folder {
//                        self.tableData[indexPath.row] = entity
                        self.provider?.items[indexPath.row] = entity
                        self.tableView.beginUpdates()
                        self.tableView.reloadRows(at: [indexPath], with: .none)
                        self.tableView.endUpdates()
                        
                        if let updatedCell = self.tableView.cellForRow(at: indexPath) {
                            self.highlight(cell: updatedCell)
                        }
                    }
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }
    
    func download(cell: UITableViewCell) {
        guard
            let fileCell = cell as? ASCFileCell,
            let file = fileCell.file,
            let provider = provider
        else {
            UIAlertController.showError(
                in: self,
                message: NSLocalizedString("Could not download file.", comment: "")
            )
            return
        }
        
        var forceCancel = false
        let openingAlert = ASCProgressAlert(
            title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...",
            message: nil,
            handler: { (cancel) in
                forceCancel = cancel
        })
        
        ASCEntityManager.shared.download(for: provider, entity: file) { [unowned self] (status, progress, result, error, cancel) in
            if status == .begin {
                openingAlert.show()
            }
            
            openingAlert.progress = progress
            
            if forceCancel {
                cancel = forceCancel
                provider.cancel()
                return
            }
            
            if status == .end || status == .error {
                if status == .error {
                    openingAlert.hide()
                    UIAlertController.showError(
                        in: self,
                        message: error ??  NSLocalizedString("Could not download file.", comment: "")
                    )
                } else {
                    if let newFile = result as? ASCFile, let rootVC = ASCViewControllerManager.shared.rootController {
                        // Switch category to 'On Device'
                        rootVC.display(provider: ASCFileManager.localProvider, folder: nil)
                        
                        // Delay so that the loading indication is completed
                        delay(seconds: 0.6) {
                            openingAlert.hide()

                            let splitVC = ASCViewControllerManager.shared.topViewController as? ASCBaseSplitViewController
                            let documentsNC = splitVC?.detailViewController as? ASCDocumentsNavigationController
                            let documentsVC: ASCDocumentsViewController? = documentsNC?.viewControllers.first as? ASCDocumentsViewController ?? ASCViewControllerManager.shared.topViewController as? ASCDocumentsViewController
                            
                            if let documentsVC = documentsVC {
                                documentsVC.loadFirstPage { success in
                                    if success {
                                        if let index = documentsVC.tableData.firstIndex(where: { ($0 as? ASCFile)?.title == newFile.title }) {
                                            // Scroll to new cell
                                            let indexPath = IndexPath(row: index, section: 0)
                                            documentsVC.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                                            
                                            // Highlight new cell
                                            delay(seconds: 0.3) {
                                                if let newCell = documentsVC.tableView.cellForRow(at: indexPath) {
                                                    documentsVC.highlight(cell: newCell)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func favorite(cell: UITableViewCell, favorite: Bool) {
        guard
            let provider = provider,
            let fileCell = cell as? ASCFileCell,
            let file = fileCell.file
        else { return }
        
        var hud: MBProgressHUD? = nil
        
        ASCEntityManager.shared.favorite(for: provider, entity: file, favorite: favorite) {  [unowned self] status, entity, error in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.mode = .indeterminate
            } else if status == .error {
                hud?.hide(animated: true)
                
                if error != nil {
                    UIAlertController.showError(in: self, message: error!)
                }
            } else if status == .end {
                if entity != nil {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: 1.3)
                    
                    if let indexPath = self.tableView.indexPath(for: cell), let file = entity as? ASCFile {
                        if categoryIsFavorite {
                            self.provider?.remove(at: indexPath.row)
                            self.tableView.beginUpdates()
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                            self.tableView.endUpdates()
                        } else {
                            self.provider?.items[indexPath.row] = file
                            self.tableView.beginUpdates()
                            self.tableView.reloadRows(at: [indexPath], with: .fade)
                            self.tableView.endUpdates()
                        }
                    }
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }

    func export(cell: UITableViewCell) {
        guard let fileCell = cell as? ASCFileCell, let file = fileCell.file else {
            UIAlertController.showError(
                in: self,
                message: NSLocalizedString("Could not export the file.", comment: "")
            )
            return
        }
        
        if file.device {
            let fileUrl = URL(fileURLWithPath: file.id)
            documentInteraction = UIDocumentInteractionController(url: fileUrl)
            documentInteraction.presentOptionsMenu(from: cell.bounds, in: cell, animated: true)
        } else {
            var forceCancel = false
            let openingAlert = ASCProgressAlert(
                title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...",
                message: nil,
                handler: { (cancel) in
                    forceCancel = cancel
            })
            
            openingAlert.show()
            
            let destinationPath = Path.userTemporary + file.title
            
            provider?.download(file.viewUrl ?? "", to: URL(fileURLWithPath:destinationPath.rawValue)) { [weak self] progress, result, error, response in
                openingAlert.progress = Float(progress)
                
                if forceCancel {
                    self?.provider?.cancel()
//                    ASCOnlyOfficeApi.cancelAllTasks()
                    return
                }

                guard let strongSelf = self else { return }

                if nil != error {
                    openingAlert.hide()
                    UIAlertController.showError(
                        in: strongSelf,
                        message: NSLocalizedString("Could not download the file.", comment: "")
                    )
                } else if nil != result {
                    openingAlert.hide()
                    
                    // Create entity info
                    let owner = ASCUser()
                    owner.displayName = UIDevice.displayName
                    
                    let file = ASCFile()
                    file.id = destinationPath.rawValue
                    file.rootFolderType = .deviceDocuments
                    file.title = destinationPath.fileName
                    file.created = destinationPath.creationDate
                    file.updated = destinationPath.modificationDate
                    file.createdBy = owner
                    file.updatedBy = owner
                    file.device = true
                    file.displayContentLength = String.fileSizeToString(with: destinationPath.fileSize ?? 0)
                    file.pureContentLength = Int(destinationPath.fileSize ?? 0)
                    
                    let fileUrl = URL(fileURLWithPath: file.id)
                    strongSelf.documentInteraction = UIDocumentInteractionController(url: fileUrl)
                    strongSelf.documentInteraction.presentOptionsMenu(from: cell.bounds, in: cell, animated: true)
                }
            }
        }
    }
    
    func copy(cell: UITableViewCell) {
        transfer(cell: cell)
    }
    
    func move(cell: UITableViewCell) {
        transfer(cell: cell, move: true)
    }
    
    func recover(cell: UITableViewCell) {
        transfer(cell: cell, move: true)
    }
    
    func duplicate(cell: UITableViewCell) {
        guard let fileCell = cell as? ASCFileCell, let file = fileCell.file, let folder = folder else {
            return
        }
        
        var hud: MBProgressHUD? = nil
        
        ASCEntityManager.shared.duplicate(file: file, to: folder) { [unowned self] (status, progress, result, error, cancel) in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.mode = .annularDeterminate
                hud?.progress = 0
                hud?.label.text = NSLocalizedString("Duplication", comment: "Caption of the processing")
            } else if status == .progress {
                hud?.progress = progress
            } else if status == .error {
                hud?.hide(animated: true)
                UIAlertController.showError(
                    in: self,
                    message: error ?? NSLocalizedString("Could not duplicate the file.", comment: "")
                )
            } else if status == .end {
                hud?.setSuccessState()
                hud?.hide(animated: false, afterDelay: 1.3)
                
                if let indexPath = self.tableView.indexPath(for: cell), let duplicate = result as? ASCFile {
                    self.provider?.add(item: duplicate, at: indexPath.row)
                    self.tableView.reloadData()
                    
                    if let newCell = self.tableView.cellForRow(at: indexPath) {
                        self.highlight(cell: newCell)
                    }
                }
            }
        }
    }
    
    func transfer(cell: UITableViewCell, move: Bool = false) {
        if let fileCell = cell as? ASCFileCell, let file = fileCell.file {
            transfer(indexes: [file.uid], move: move)
        } else if let folderCell = cell as? ASCFolderCell, let folder = folderCell.folder {
            transfer(indexes: [folder.uid], move: move)
        }
    }

    private func insideTransfer(
        items: [ASCEntity],
        to folder: ASCFolder,
        move: Bool = false,
        overwride: Bool = false,
        completion: (([ASCEntity]?) -> Void)? = nil)
    {
        guard let provider = provider else { return }

        var hud: MBProgressHUD?
        var isTrash = false

        if let parent = (items.first as? ASCFolder)?.parent ?? (items.first as? ASCFile)?.parent {
            isTrash = self.isTrash(parent)
        }

        provider.transfer(
            items: items,
            to: folder,
            move: move,
            overwrite: overwride,
            handler:
        { status, progress, result, error, cancel in
            if status == .begin {
                if hud == nil {
                    hud = MBProgressHUD.showTopMost()
                    hud?.mode = .annularDeterminate
                    hud?.progress = 0
                    hud?.label.text = move
                        ? (isTrash
                            ? NSLocalizedString("Recovery", comment: "Caption of the processing")
                            : NSLocalizedString("Moving", comment: "Caption of the processing"))
                        : NSLocalizedString("Copying", comment: "Caption of the processing")
                }
            } else if status == .progress {
                hud?.progress = progress
            } else if status == .error {
                hud?.hide(animated: false)
                UIAlertController.showError(
                    in: self,
                    message: error ?? NSLocalizedString("Could not copy.", comment: "")
                )
                completion?(nil)
            } else if status == .end {
                hud?.setSuccessState()
                hud?.hide(animated: false, afterDelay: 1.3)

                completion?(items)
            }
        })
    }

    private func insideCheckTransfer(
        items: [ASCEntity],
        to folder: ASCFolder,
        move: Bool = false,
        complation: @escaping ((_ overwride: Bool, _ cancel: Bool) -> Void))
    {
        guard let provider = provider else { return }

        var hud: MBProgressHUD?
        let isTrash = self.isTrash(folder)

        provider.chechTransfer(items: items, to: folder, handler: { status, result, error in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.mode = .indeterminate
                hud?.label.text = move
                    ? (isTrash
                        ? NSLocalizedString("Recovery", comment: "Caption of the processing")
                        : NSLocalizedString("Moving", comment: "Caption of the processing"))
                    : NSLocalizedString("Copying", comment: "Caption of the processing")
            } else if status == .error {
                hud?.hide(animated: false)
                UIAlertController.showError(
                    in: self,
                    message: error ?? NSLocalizedString("Could not copy.", comment: "")
                )
            } else if status == .end {
                hud?.hide(animated: false)

                if let conflicts = result as? [Any], conflicts.count > 0 {
                    let title = (conflicts.first as? ASCFolder)?.title ?? (conflicts.first as? ASCFile)?.title ?? ""
                    let message = conflicts.count > 1
                        ? String(format: NSLocalizedString("%lu items with the same name already exist in the folder '%@'. Overwrite the items?", comment: ""), conflicts.count, folder.title)
                        : String(format: NSLocalizedString("The item with the name '%@' already exists in the folder '%@'.", comment: ""), title, folder.title)

                    let alertController = UIAlertController(
                        title: NSLocalizedString("Overwrite confirmation", comment:"Button title"),
                        message: message,
                        preferredStyle: .alert,
                        tintColor: nil
                    )

                    alertController.addAction(
                        UIAlertAction(
                            title: NSLocalizedString("Overwrite", comment: "Button title"),
                            style: .default,
                            handler: { action in
                                complation(true, false)
                        })
                    )

                    alertController.addAction(
                        UIAlertAction(
                            title: NSLocalizedString("Skip", comment: "Button title"),
                            style: .default,
                            handler: { action in
                                complation(false, false)
                        })
                    )

                    alertController.addAction(
                        UIAlertAction(
                            title: ASCLocalization.Common.cancel,
                            style: .cancel,
                            handler: { action in
                                complation(false, true)
                        })
                    )

                    self.present(alertController, animated: true, completion: nil)
                } else {
                    complation(false, false)
                }
            }
        })
    }


    func transfer(indexes: Set<String>, move: Bool = false) {
        var entities: [ASCEntity] = []

        for uid in indexes {
            if let entity = tableData.first(where: { $0.uid == uid }) {
                entities.append(entity)
            }
        }

        func transferViaManager(items: [ASCEntity], completion: (([ASCEntity]?) -> Void)? = nil) {
            if items.count < 1 {
                completion?(nil)
                return
            }

            let transferNavigationVC = ASCTransferNavigationController.instantiate(from: Storyboard.transfer)

            if UIDevice.pad {
                transferNavigationVC.modalPresentationStyle = .formSheet
                transferNavigationVC.preferredContentSize = CGSize(width: ASCConstants.Size.defaultPreferredContentSize.width, height: 520)
            }

            self.present(transferNavigationVC, animated: true, completion: nil)

            transferNavigationVC.sourceProvider = provider
            transferNavigationVC.sourceFolder = folder
            transferNavigationVC.sourceItems = entities
            transferNavigationVC.doneHandler = { [weak self] destProvider, destFolder in
                guard
                    let strongSelf = self,
                    let provider = destProvider,
                    let folder = destFolder
                    else { return }

                let isTrash = strongSelf.isTrash(folder)
                let isInsideTransfer = (strongSelf.provider?.id == provider.id) && !(strongSelf.provider is ASCGoogleDriveProvider)

                if isInsideTransfer {
                    strongSelf.insideCheckTransfer(items: items, to: folder, move: move, complation: { overwride, cancel in
                        if cancel {
                            completion?(nil)
                        } else {
                            strongSelf.insideTransfer(items: items, to: folder, move: move, overwride: overwride, completion: { entities in
                                completion?(entities)
                                guard let transfers = entities else {
                                    completion?(nil)
                                    return
                                }
                                
                                if move {
                                    transferNavigationVC.sourceProvider?.items.removeAll(transfers)
                                    strongSelf.tableView.reloadData()
                                }
                                
                                if let destVC = getLoadedViewController(byFolderId: folder.id, andProviderId: provider.id) {
                                    destVC.loadFirstPage()
                                }
                            })
                        }
                    })
                } else {
                    if  let srcProvider = self?.provider,
                        let destProvider = destProvider,
                        let destFolder = destFolder
                    {
                        var forceCancel = false
                        let transferAlert = ASCProgressAlert(
                            title: move
                                ? (isTrash
                                    ? NSLocalizedString("Recovery", comment: "Caption of the processing")
                                    : NSLocalizedString("Moving", comment: "Caption of the processing"))
                                : NSLocalizedString("Copying", comment: "Caption of the processing"),
                            message: nil,
                            handler:
                            { cancel in
                                forceCancel = cancel
                        })

                        transferAlert.show()
                        transferAlert.progress = 0

                        ASCEntityManager.shared.transfer(from: (items:items, provider: srcProvider),
                                                         to: (folder: destFolder, provider: destProvider),
                                                         move: move,
                                                         handler:
                            { [weak self] progress, complate, success, newItems, error, cancel in
                                log.debug("Transfer procress: \(Int(progress * 100))%")

                                if forceCancel {
                                    cancel = forceCancel
                                }

                                DispatchQueue.main.async { [items, newItems] in
                                    if complate {
                                        transferAlert.hide()

                                        if success {
                                            completion?(nil)
                                            
                                            if !items.isEmpty, let destVC = getLoadedViewController(byFolderId: destFolder.id, andProviderId: destProvider.id) {
                                                
                                                if let transfers = newItems, items.count == transfers.count {
                                                    insert(transferedItems: transfers, toLoadedViewController: destVC)
                                                } else {
                                                    destVC.loadFirstPage()
                                                }
                                            }
                                        } else {
                                            completion?(items)
                                        }
                                        
                                        if let strongSelf = self {
                                            if srcProvider.type != .local || destProvider.type != .local,
                                                !ASCNetworkReachability.shared.isReachable
                                            {
                                                UIAlertController.showError(
                                                    in: strongSelf,
                                                    message: NSLocalizedString("Check your internet connection", comment: "")
                                                )
                                            } else {
                                                if !success, let error = error {
                                                    UIAlertController.showError(
                                                        in: strongSelf,
                                                        message: error.localizedDescription
                                                    )
                                                }
                                            }
                                        }
                                    } else {
                                        transferAlert.progress = progress
                                    }
                                }
                        })
                    }
                }
            }

            if let transferViewController = transferNavigationVC.topViewController as? ASCTransferViewController {
                transferNavigationVC.transferType = isTrash(folder) ? .recover : (move ? .move : .copy)
                // transferNavigationController.transferMode = type
                transferViewController.folder = nil
            }
        }
        
        transferViaManager(items: entities) { [unowned self] errorItems in
            guard let provider = self.provider else { return }
            
            if move {
                var deteteIndexes: [IndexPath] = []
                let errorItemIds: [String] = errorItems?.map { $0.id } ?? []

                for item in entities {
                    if let indexPath = self.indexPath(by: item) {
                        if !errorItemIds.contains(item.id) {
                            // Store remove indexes
                            deteteIndexes.append(indexPath)
                            
                            // Remove data
                            provider.remove(at: indexPath.row)
                        }
                    }
                }

                // Update table view
                self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)

                self.showEmptyView(self.total < 1)
                self.updateNavBar()
            }

            self.setEditMode(false)
        }
        
        func insert(transferedItems items: [ASCEntity], toLoadedViewController viewController: ASCDocumentsViewController)
        {
            guard !items.isEmpty, let provider = viewController.provider else { return }
            
            provider.add(items: items, at: 0)
            provider.updateSort(completeon: { _, _, _, _ in
                viewController.tableView.reloadData()
            })
            
            viewController.showEmptyView(viewController.total < 1)
            viewController.showErrorView(false)
            viewController.updateNavBar()
        }
        
        func getLoadedViewController(byFolderId folderId: String?, andProviderId providerId: String?) -> ASCDocumentsViewController? {
            guard let folderId = folderId, !folderId.isEmpty,
                  let providerId = providerId, !providerId.isEmpty
            else {
                return nil
            }
            
            let request = ASCLoadedVCFinderModels.DocumentsVC.Request(folderId: folderId, providerId: providerId)
            let response = self.loadedDocumentsViewControllerFinder.find(requestModel: request)
            
            guard let destinationVC = response.viewController else {
                return nil
            }
            
            return destinationVC
        }
    }
    
    func delete(indexes: Set<String>) {
        guard
            let provider = provider,
            let folder = folder
        else { return }
        
        var localItems: [ASCEntity] = []
        var cloudItems: [ASCEntity] = []
        
        for uid in indexes {
            if let index = tableData.firstIndex(where: { $0.uid == uid }) {
                if let file = tableData[index] as? ASCFile {
                    file.device ? localItems.append(file) : cloudItems.append(file)
                } else if let folder = tableData[index] as? ASCFolder {
                    folder.device ? localItems.append(folder) : cloudItems.append(folder)
                }
            }
        }
        
        func deleteGroup(items: [ASCEntity], completion: (([ASCEntity]?) -> Void)? = nil) {
            if items.count < 1 {
                completion?(nil)
                return
            }
            
            var hud: MBProgressHUD? = nil
            
            ASCEntityManager.shared.delete(for: provider, entities: items, from: folder) { (status, result, error) in
                if status == .begin {
                    if hud == nil {
                        hud = MBProgressHUD.showTopMost()
                        hud?.mode = .indeterminate
                        hud?.label.text = NSLocalizedString("Deleting", comment: "Caption of the processing")
                    }
                } else if status == .error {
                    hud?.hide(animated: true)
                    hud = nil
                    UIAlertController.showError(
                        in: self,
                        message: error ?? NSLocalizedString("Could not delete.", comment: "")
                    )
                    completion?(nil)
                } else if status == .end {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: 1.3)
                    hud = nil
                    
                    let deletedItems = items.filter { provider.allowDelete(entity: $0) }
                    completion?(deletedItems)
                }
            }
        }
        
        var deteteItems: [ASCEntity] = []
        deleteGroup(items: localItems) { [unowned self] items in
            deteteItems += items ?? []
            
            deleteGroup(items: cloudItems) { [unowned self] items in
                deteteItems += items ?? []
                
                var deteteIndexes: [IndexPath] = []
                
                self.tableView.beginUpdates()
                
                // Store remove indexes
                for item in deteteItems {
                    if let indexPath = self.indexPath(by: item) {
                        deteteIndexes.append(indexPath)
                    }
                }
                
                // Remove data
                for item in deteteItems {
                    if let indexPath = self.indexPath(by: item) {
//                        self.tableData.remove(at: indexPath.row)
//                        self.total -= 1
                        self.provider?.remove(at: indexPath.row)
                    }
                }
                
                // Remove cells
                self.tableView.deleteRows(at: deteteIndexes, with: .fade)
                self.tableView.endUpdates()
                
                self.showEmptyView(self.total < 1)
                self.updateNavBar()
                self.setEditMode(false)
            }
        }
    }
    
    func emptyTrash() {
        var hud: MBProgressHUD? = nil
        
        ASCEntityManager.shared.emptyTrash() { [unowned self] (status, progress, result, error, cancel) in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.mode = .annularDeterminate
                hud?.progress = 0
                hud?.label.text = NSLocalizedString("Cleanup", comment: "Caption of the processing")
            } else if status == .progress {
                hud?.progress = progress
            } else if status == .error {
                hud?.hide(animated: true)
                UIAlertController.showError(
                    in: self,
                    message: error ?? NSLocalizedString("Could not empty trash.", comment: "")
                )
            } else if status == .end {
                hud?.setSuccessState()
                hud?.hide(animated: false, afterDelay: 1.3)

                if self.isTrash(self.folder) {
//                    self.tableData.removeAll()
//                    self.total = 0
                    self.provider?.reset()
                    self.tableView.reloadData()
                }
                
                self.showEmptyView(self.total < 1)
                self.updateNavBar()
                self.setEditMode(false)
            }
        }
    }

    private func selectAllItems<T>(type: T.Type, extensions:[String]? = nil) {
        if type == ASCFile.self {
            var files: [ASCEntity] = []
            if let extensions = extensions {
                files = tableData.filter{ $0 is ASCFile && extensions.contains(($0 as? ASCFile)?.title.fileExtension().lowercased() ?? "") }
            } else {
                files = tableData.filter{ $0 is ASCFile }
            }
            let selectedFiles = files.filter{ selectedIds.contains($0.uid) }
            selectedIds = (
                (selectedFiles.count == selectedIds.count)
                    && (selectedFiles.count == files.count)
                    && selectedFiles.count > 0)
                ? []
                : Set(files.map{ $0.uid }
            )
        } else if type == ASCFolder.self {
            let folders = tableData.filter{ $0 is ASCFolder }
            let selectedFolders = folders.filter{ selectedIds.contains($0.uid) }
            selectedIds = (
                (selectedFolders.count == selectedIds.count)
                    && (selectedFolders.count == folders.count)
                    && selectedFolders.count > 0)
                ? []
                : Set(folders.map{ $0.uid }
            )
        } else {
            selectedIds = selectedIds.count == tableData.count
                ? []
                : Set(tableData.map{ $0.uid })
        }

        updateSelectedInfo()
        
        tableView.reloadSections([0], with: .fade)
        
        events.trigger(eventName: "item:didSelect")
    }
    
    // MARK: - Actions

    @objc func onSelectAll(_ sender: Any) {
        let selectController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )

        selectController.addAction(UIAlertAction(title: NSLocalizedString("All", comment: ""), handler: { [weak self] action in
            self?.selectAllItems(type: AnyObject.self)
        }))
        selectController.addAction(UIAlertAction(title: NSLocalizedString("Files", comment: ""), handler: { [weak self] action in
            self?.selectAllItems(type: ASCFile.self)
        }))
        selectController.addAction(UIAlertAction(title: NSLocalizedString("Folders", comment: ""), handler: { [weak self] action in
            self?.selectAllItems(type: ASCFolder.self)
        }))
        selectController.addAction(UIAlertAction(title: NSLocalizedString("Documents", comment: ""), handler: { [weak self] action in
            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.documents)
        }))
        selectController.addAction(UIAlertAction(title: NSLocalizedString("Spreadsheets", comment: ""), handler: { [weak self] action in
            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.spreadsheets)
        }))
        selectController.addAction(UIAlertAction(title: NSLocalizedString("Presentations", comment: ""), handler: { [weak self] action in
            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.presentations)
        }))
        selectController.addAction(UIAlertAction(title: NSLocalizedString("Images", comment: ""), handler: { [weak self] action in
            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.images)
        }))

        selectController.addAction(UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel, handler: nil))

        if UIDevice.pad {
            selectController.modalPresentationStyle = .popover

            if let barButtonItem = sender as? UIBarButtonItem {
                selectController.popoverPresentationController?.barButtonItem = barButtonItem
            }
        }

        present(selectController, animated: true, completion: nil)
    }

    @objc func onCopySelected(_ sender: Any) {
        transfer(indexes: selectedIds)
    }
    
    @objc func onMoveSelected(_ sender: Any) {
        transfer(indexes: selectedIds, move: true)
    }
    
    @objc func onTrashSelected(_ sender: Any) {
        guard view.isUserInteractionEnabled else { return }
        
        if selectedIds.count > 0 {
            let selectetItems = tableData.filter{ selectedIds.contains($0.uid) }
            let folderCount = selectetItems.filter{ $0 is ASCFolder }.count
            let fileCount = selectetItems.filter{ $0 is ASCFile }.count
            
            var message = NSLocalizedString("Delete", comment: "")
            
            if folderCount > 0 && fileCount > 0 {
                message = String(format: NSLocalizedString("Delete %lu Folder and %lu File", comment: ""), folderCount, fileCount)
            } else if folderCount > 0 {
                message = String(format: NSLocalizedString("Delete %lu Folder", comment: ""), folderCount)
            } else if fileCount > 0 {
                message = String(format: NSLocalizedString("Delete %lu File", comment: ""), fileCount)
            }
            
            let deleteController = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .actionSheet,
                tintColor: nil
            )
            
            deleteController.addAction(
                UIAlertAction(
                    title:message,
                    style: .destructive,
                    handler: { [unowned self] (action) in
                        self.delete(indexes: self.selectedIds)
                })
            )
            
            if UIDevice.phone {
                deleteController.addAction(
                    UIAlertAction(
                        title: ASCLocalization.Common.cancel,
                        style: .cancel,
                        handler: nil
                    )
                )
            } else if UIDevice.pad, let button = sender as? UIButton {
                deleteController.modalPresentationStyle = .popover
                deleteController.popoverPresentationController?.sourceView = button
                deleteController.popoverPresentationController?.sourceRect = button.bounds
                flashBlockInteration()
            }

            present(deleteController, animated: true, completion: nil)
        }
    }
    
    @objc func onEmptyTrashSelected(_ sender: UIBarButtonItem) {
        if isTrash(folder) {
            emptyTrash()
        }
    }

    // MARK: - Actions

    @IBAction func createFirstItem(_ sender: UIButton) {
        guard let provider = provider else { return }
        ASCCreateEntity().showCreateController(for: provider, in: self, sender: sender)
    }
    
    @IBAction func onErrorRetry(_ sender: UIButton) {
        loadFirstPage()
    }
}

// MARK: - UISearchControllerDelegate

extension ASCDocumentsViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        if #available(iOS 11.0, *) {
            //
        } else {
            searchBackground.frame = CGRect(
                x: 0,
                y: 0,
                width: searchController.searchBar.frame.size.width,
                height: searchController.searchBar.frame.size.height + ASCCommon.statusBarHeight
            )
            searchController.view?.insertSubview(searchBackground, at: 0)

            searchSeparator.frame = CGRect(
                x: 0,
                y: searchController.searchBar.frame.size.height + ASCCommon.statusBarHeight,
                width: searchController.searchBar.frame.size.width,
                height: UIDevice.screenPixel
            )
            searchSeparator.alpha = 1
            searchController.view?.insertSubview(searchSeparator, at: 0)
        }
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        searchSeparator.alpha = 0
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        ASCOnlyOfficeApi.cancelAllTasks()

//        provider?.page = 0
//        total = 0
//        tableData.removeAll()
        provider?.reset()
        tableView.reloadData()

        showLoadingPage(true)

        fetchData({ [weak self] success in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }

                strongSelf.showLoadingPage(false)
                strongSelf.showErrorView(!success)

                if success {
                    strongSelf.showEmptyView(strongSelf.total < 1)
                }

                strongSelf.updateNavBar()
            }
        })
    }
}

// MARK: - UISearchResultsUpdating

extension ASCDocumentsViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        /// Throttle search
        
        searchTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.sendSearchRequest()
        }
        searchTask = task

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.75, execute: task)
    }
    
    private func sendSearchRequest() {
        var searchText: String?
        
        if searchController.isActive {
            if let search = searchController.searchBar.text?.trimmed.lowercased(), search.count > 0 {
                searchText = search
            }
        }
        
        if searchValue != searchText {
            searchValue = searchText
            
            provider?.page = 0
            
            fetchData({ [weak self] success in
                DispatchQueue.main.async {
                    guard let strongSelf = self else { return }
                    strongSelf.updateNavBar()
                    strongSelf.events.trigger(eventName: "item:didSelect")
                }
            })
        }
    }
}

// MARK: - MGSwipeTableCellDelegate

extension ASCDocumentsViewController: MGSwipeTableCellDelegate {
    func swipeTableCell(_ cell: MGSwipeTableCell, canSwipe direction: MGSwipeDirection, from point: CGPoint) -> Bool {
        return direction != .leftToRight
    }

    func swipeTableCell(_ cell: MGSwipeTableCell, swipeButtonsFor direction: MGSwipeDirection, swipeSettings: MGSwipeSettings, expansionSettings: MGSwipeExpansionSettings) -> [UIView]? {
        swipeSettings.transition = .border

        if direction == .rightToLeft {
            if let fileCell = cell as? ASCFileCell {
                return fileMenu(cell: fileCell)
            } else if let folderCell = cell as? ASCFolderCell {
                return folderMenu(cell: folderCell)
            }
        }

        return nil
    }
}

// MARK: - ASCProvider Delegate

extension ASCDocumentsViewController: ASCProviderDelegate {
    
    func openProgress(file: ASCFile, title: String, _ progress: Float) -> ASCEditorManagerOpenHandler {
        var forceCancel = false
        let openingAlert = ASCProgressAlert(title: title, message: nil, handler: { cancel in
            forceCancel = cancel
        })

        openingAlert.show()
        openingAlert.progress = progress

        let openHandler: ASCEditorManagerOpenHandler = { [weak self] status, progress, error, cancel in
            log.info("Open file progress. Status: \(status), progress: \(progress), error: \(String(describing: error))")

            openingAlert.progress = progress

            if forceCancel {
                cancel = forceCancel
                self?.provider?.cancel()
                return
            }

            if status == .end || status == .error || status == .silentError {
                openingAlert.hide()

                if status == .error {
                    guard let strongSelf = self else { return }

                    UIAlertController.showError(
                        in: strongSelf,
                        message: error?.localizedDescription ?? NSLocalizedString("Could not open file.", comment: "")
                    )
                }
            }
        }

        return openHandler
    }

    func closeProgress(file: ASCFile, title: String) -> ASCEditorManagerCloseHandler {
        var hud: MBProgressHUD? = nil

        let originalFile = file
        let closeHandler: ASCEditorManagerCloseHandler = { [weak self] status, progress, file, error, cancel in
            log.info("Close file progress. Status: \(status), progress: \(progress), error: \(String(describing: error))")

            if status == .begin {
                if nil == hud && file?.device == true {
                    hud = MBProgressHUD.showTopMost()
                    hud?.mode = .indeterminate
                    hud?.label.text = title
                }
            } else if status == .error {
                hud?.hide(animated: true)

                guard let strongSelf = self else { return }

                if error != nil {
                    UIAlertController.showError(
                        in: strongSelf,
                        message: error?.localizedDescription ?? NSLocalizedString("Could not save the file.", comment: "")
                    )
                }
            } else if status == .end {
                hud?.setSuccessState()
                hud?.hide(animated: false, afterDelay: 1.3)

                SwiftRater.incrementSignificantUsageCount()

                guard let strongSelf = self else { return }

                /// Update file info
                let updateFileInfo = {
                    if let newFile = file {
                        if let index = strongSelf.tableData.firstIndex(where: { (entity) -> Bool in
                            guard let file = entity as? ASCFile else { return false }
                            return file.id == newFile.id || file.id == originalFile.id
                        }) {
//                            strongSelf.tableData[index] = newFile
                            strongSelf.provider?.items[index] = newFile

                            let indexPath = IndexPath(row: index, section: 0)

                            strongSelf.tableView.beginUpdates()
                            strongSelf.tableView.reloadRows(at: [indexPath], with: .none)
                            strongSelf.tableView.endUpdates()

                            if let updatedCell = strongSelf.tableView.cellForRow(at: indexPath) {
                                strongSelf.highlight(cell: updatedCell)
                            }
                        } else {
                            strongSelf.provider?.add(item: newFile, at: 0)
                            strongSelf.tableView.reloadData()
                            strongSelf.showEmptyView(strongSelf.total < 1)
                            strongSelf.updateNavBar()
                            
                            let updateIndexPath = IndexPath(row: 0, section: 0)
                            strongSelf.tableView.scrollToRow(at: updateIndexPath, at: .top, animated: true)
                            
                            if let updatedCell = strongSelf.tableView.cellForRow(at: updateIndexPath) {
                                strongSelf.highlight(cell: updatedCell)
                            }
                        }
                    }
                }

                if strongSelf.provider?.type == .local {
                    strongSelf.loadFirstPage { success in
                        updateFileInfo()
                    }
                } else {
                    updateFileInfo()
                }
            }
        }

        return closeHandler
    }
    
    func updateItems(provider: ASCFileProviderProtocol) {
//        total = provider.total
//        tableData = provider.items
        tableView.reloadData()
        
        // TODO: Or search diff and do it animated
        
        showEmptyView(total < 1)
    }
    
    func presentShareController(provider: ASCFileProviderProtocol, entity: ASCEntity) {
        if let keyWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first {
            if var topController = keyWindow.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                presentShareController(in: topController, entity: entity)
            }
        }
    }
}

// MARK: - UITableViewDragDelegate

extension ASCDocumentsViewController: UITableViewDragDelegate {

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {

        if let _ = tableView.cellForRow(at: indexPath), let providerId = provider?.id {
            let documentItemProvider = ASCEntityItemProvider(providerId: providerId, entity: tableData[indexPath.row])
            let itemProvider = NSItemProvider(object: documentItemProvider)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            return [dragItem]
        }
        return []
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        guard let folder = folder else { return }

        session.localContext = [
            "srcFolder": folder,
            "srcController": self
        ]
        setEditMode(false)
    }
}

// MARK: - UITableViewDropDelegate

extension ASCDocumentsViewController: UITableViewDropDelegate {
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        var srcFolder: ASCFolder?
        var dstFolder = folder
        var srcProvider: ASCFileProviderProtocol?
        let dstProvider = provider
        var srcProviderId: String?
        var items: [ASCEntity] = []

        if let destinationIndexPath = coordinator.destinationIndexPath {
            if let folder = tableData[min(destinationIndexPath.row, tableData.count - 1)] as? ASCFolder {
                dstFolder = folder
            }
        }

        for item in coordinator.items {
            let semaphore = DispatchSemaphore(value: 0)
            item.dragItem.itemProvider.loadObject(ofClass: ASCEntityItemProvider.self, completionHandler: { entityProvider, error in
                if let entityProvider = entityProvider as? ASCEntityItemProvider {
                    srcProviderId = entityProvider.providerId
                    
                    if let file = entityProvider.entity as? ASCFile {
                        items.append(file)
                    } else if let folder = entityProvider.entity as? ASCFolder {
                        items.append(folder)
                    }
                }
                semaphore.signal()
            })
            semaphore.wait()
        }

        if items.count < 1 {
            return
        }

        if let srcProviderId = srcProviderId {
            if srcProviderId == ASCFileManager.localProvider.id {
                srcProvider = ASCFileManager.localProvider
            } else if srcProviderId == ASCFileManager.onlyofficeProvider?.id {
                srcProvider = ASCFileManager.onlyofficeProvider
            } else {
                srcProvider = ASCFileManager.cloudProviders.first(where: { $0.id == srcProviderId })
            }
        }

        let contextInfo = coordinator.session.localDragSession?.localContext as? [String: Any]

        if let contextInfo = contextInfo {
            srcFolder = contextInfo["srcFolder"] as? ASCFolder

            // Hotfix parent of items for some providers
            for item in items {
                if let file = item as? ASCFile {
                    file.parent = srcFolder
                }
                if let folder = item as? ASCFolder {
                    folder.parent = srcFolder
                }
            }
        }

        if  let srcProvider = srcProvider,
            let dstProvider = dstProvider,
            let srcFolder = srcFolder,
            let dstFolder = dstFolder
        {
            let move = srcProvider.allowDelete(entity: items.first)
            let isInsideTransfer = (srcProvider.id == dstProvider.id) && !(srcProvider is ASCGoogleDriveProvider)
            
            if !isInsideTransfer {
                var forceCancel = false

                let transferAlert = ASCProgressAlert(
                    title: move
                        ? (isTrash(srcFolder)
                            ? NSLocalizedString("Recovery", comment: "Caption of the processing")
                            : NSLocalizedString("Moving", comment: "Caption of the processing"))
                        : NSLocalizedString("Copying", comment: "Caption of the processing"),
                    message: nil,
                    handler:
                    { cancel in
                        forceCancel = cancel
                })

                transferAlert.show()
                transferAlert.progress = 0

                ASCEntityManager.shared.transfer(from: (items: items, provider: srcProvider),
                                                 to: (folder: dstFolder, provider: dstProvider),
                                                 move: move)
                { [weak self] progress, complate, success, newItems, error, cancel in
                    log.debug("Transfer procress: \(Int(progress * 100))%")

                    if forceCancel {
                        cancel = forceCancel
                    }

                    DispatchQueue.main.async { [weak self] in
                        if complate {
                            transferAlert.hide()

                            if success {
                                log.info("Items copied")

                                guard let strongSelf = self else { return }

                                // Append new items to destination controller
                                if let newItems = newItems, dstFolder.id == strongSelf.folder?.id {
                                    strongSelf.provider?.add(items: newItems, at: 0)
                                    strongSelf.tableView.reloadData()

                                    for index in 0..<newItems.count {
                                        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
                                            strongSelf.highlight(cell: cell)
                                        }
                                    }
                                }

                                // Remove items from source controller if move
                                if move,
                                    let contextInfo = contextInfo,
                                    let srcDocumentsVC = contextInfo["srcController"] as? ASCDocumentsViewController
                                {
                                    for item in items {
                                        if let index = srcDocumentsVC.tableData.firstIndex(where: { $0.id == item.id }) {
                                            srcDocumentsVC.provider?.remove(at: index)
                                        }
                                    }
                                    srcDocumentsVC.tableView?.reloadData()
                                }
                            } else {
                                log.error("Items don't copied")
                            }
                            
                            if let strongSelf = self,
                                srcProvider.type != .local || dstProvider.type != .local,
                                !ASCNetworkReachability.shared.isReachable
                            {
                                UIAlertController.showError(
                                    in: strongSelf,
                                    message: NSLocalizedString("Check your internet connection", comment: "")
                                )
                            }

                        } else {
                            transferAlert.progress = progress
                        }
                    }
                }
            } else {
                insideCheckTransfer(items: items, to: dstFolder, move: move, complation: { [weak self] overwride, cancel in
                    guard
                        let strongSelf = self,
                        let folder = strongSelf.folder
                    else { return }

                    // If open folder is destination
                    let isSameFolder = dstFolder.id == folder.id

                    if !cancel {
                        strongSelf.insideTransfer(items: items, to: dstFolder, move: move, overwride: overwride, completion: { entities in
                            if isSameFolder {
                                strongSelf.loadFirstPage()
                            } else {
                                if move {
                                    guard let entities = entities else { return }

                                    var deteteIndexes: [IndexPath] = []

                                    strongSelf.tableView.beginUpdates()

                                    // Store remove indexes
                                    for item in entities {
                                        if let indexPath = strongSelf.indexPath(by: item) {
                                            deteteIndexes.append(indexPath)
                                        }
                                    }

                                    // Remove data
                                    for item in entities {
                                        if let indexPath = strongSelf.indexPath(by: item) {
                                            strongSelf.provider?.remove(at: indexPath.row)
//                                            strongSelf.tableData.remove(at: indexPath.row)
//                                            strongSelf.total -= 1
                                        }
                                    }

                                    // Remove cells
                                    strongSelf.tableView.deleteRows(at: deteteIndexes, with: .fade)
                                    strongSelf.tableView.endUpdates()

                                    strongSelf.showEmptyView(strongSelf.total < 1)
                                    strongSelf.updateNavBar()
                                }
                            }
                        })
                    }
                })
            }
        }
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        if session.canLoadObjects(ofClass: ASCEntityItemProvider.self), let folder = folder {
            if let provider = provider, provider.allowEdit(entity: folder), !isTrash(folder) {
                return true
            }
        }
        return false
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if session.localDragSession != nil {
            if let provider = provider, provider.allowEdit(entity: folder) {
                if let indexPath = destinationIndexPath, indexPath.row < tableData.count, let _ = tableData[indexPath.row] as? ASCFolder {
                    return UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
                }

                // Check if not source folder
                if let contextInfo = session.localDragSession?.localContext as? [String: Any],
                    let srcFolder = contextInfo["srcFolder"] as? ASCFolder,
                    srcFolder.uid != folder?.uid
                {
                    return UITableViewDropProposal(operation: .copy)
                }
            }
        }
        return UITableViewDropProposal(operation: .forbidden)
    }
}
