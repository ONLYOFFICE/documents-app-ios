//
//  ASCDocumentsViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 2/2/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Alamofire
import FileKit
import MBProgressHUD
import MGSwipeTableCell
import ObjectMapper
import SwiftMessages
import SwiftRater
import UIKit

typealias MovedEntities = [ASCEntity]
typealias UnmovedEntities = [ASCEntity]

class ASCDocumentsViewController: ASCBaseTableViewController, UIGestureRecognizerDelegate {
    static let identifier = String(describing: ASCDocumentsViewController.self)

    // MARK: - Public

    var folder: ASCFolder? {
        didSet {
            folderHolders.forEach { $0.folder = folder }
            if oldValue == nil, folder != nil {
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
            fileProviderHolders.forEach { $0.provider = provider }
        }
    }

    // MARK: - Private

    private lazy var loadedDocumentsViewControllerFinder: ASCLoadedViewControllerFinderProtocol = ASCLoadedDocumentViewControllerByProviderAndFolderFinder()
    private var total: Int {
        return provider?.total ?? 0
    }

    private var tableData: [ASCEntity] {
        return provider?.items ?? []
    }

    private var selectedIds: Set<String> = []
    private let kPageLoadingCellTag = 7777
    private var highlightEntity: ASCEntity?
    private var hideableViewControllerOnTransition: UIViewController?
    private var needsToLoadFirstPageOnAppear = false

    // MARK: - Actions controllers vars

    private lazy var removerActionController: ASCEntityRemoverActionController & FileProviderHolder & FolderHolder = ASCDocumentsEntityRemoverActionController(
        provider: provider,
        folder: folder,
        itemsGetter: getLocalAndCloudItems,
        providerIndexesGetter: getProviderIndexes,
        removedItemsHandler: removedItems,
        errorHandeler: removeErrorHandler
    )

    // MARK: - Menu vars

    // MARK: - TODO use it after ASCDocumentsFolderCellContextMenu will be ready

    private lazy var folderCellContextMenu: ASCDocumentsFolderCellContextMenu & FileProviderHolder & FolderHolder = ASCDocumentsFolderCellContextMenu(
        provider: provider,
        folder: folder,
        removerActionController: removerActionController,
        deleteIfNeededhandler: deleteIfNeeded
    )

    // FileProviderHolders getter
    private var fileProviderHolders: [FileProviderHolder] {
        [removerActionController, folderCellContextMenu]
    }

    // FolderHolders getter
    private var folderHolders: [FolderHolder] {
        [removerActionController, folderCellContextMenu]
    }

    // Navigation bar
    private var addBarButton: UIBarButtonItem?
    private var sortSelectBarButton: UIBarButtonItem?
    private var sortBarButton: UIBarButtonItem?
    private var selectBarButton: UIBarButtonItem?
    private var cancelBarButton: UIBarButtonItem?
    private var selectAllBarButton: UIBarButtonItem?
    private var filterBarButton: UIBarButtonItem?

    // Search
    private lazy var searchController: UISearchController = {
        $0.delegate = self
        $0.searchResultsUpdater = self
        $0.searchBar.searchBarStyle = .minimal
        $0.searchBar.tintColor = view.tintColor

        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        } else {
            navigationItem.searchController = nil
            navigationItem.hidesSearchBarWhenScrolling = featureLargeTitle
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
    @IBOutlet var emptyCreateInfo: UILabel!
    @IBOutlet var emptyCreateButton: UIButton!
    @IBOutlet var emptyCenterCostraint: NSLayoutConstraint!
    @IBOutlet var retryButton: UIButton!
    @IBOutlet var errorSubtitleLabel: UILabel!

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
        addObserver(ASCConstants.Notifications.appDidBecomeActive, #selector(onAppDidBecomeActive(_:)))
        addObserver(ASCConstants.Notifications.reloadData, #selector(onReloadData(_:)))
        addObserver(UIApplication.willResignActiveNotification, #selector(onAppMovedToBackground))
        addObserver(UIApplication.didEnterBackgroundNotification, #selector(onAppDidEnterBackground))

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
        cleanup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if needsToLoadFirstPageOnAppear {
            needsToLoadFirstPageOnAppear.toggle()
            loadFirstPage()
        }

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

        configureNavigationBar()
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

        if parent == nil {
            cleanup()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        let isViewControllerVisible = viewIfLoaded?.window != nil
        if keyPath == ASCConstants.SettingsKeys.sortDocuments {
            guard isViewControllerVisible else {
                if provider?.id == ASCFileManager.localProvider.id {
                    needsToLoadFirstPageOnAppear = true
                } else {
                    needsToLoadFirstPageOnAppear = provider?.authorization != nil
                }
                return
            }
            loadFirstPage()
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
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

    private func cleanup() {
        if provider == nil {
            return
        }

        provider = nil
        UserDefaults.standard.removeObserver(self, forKeyPath: ASCConstants.SettingsKeys.sortDocuments)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public

    func reset() {
        ASCFileManager.reset()

        provider?.cancel()
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

        fetchData { [weak self] success in
            DispatchQueue.main.async {
                refreshControl.endRefreshing()

                guard let strongSelf = self else { return }

                strongSelf.showErrorView(!success)

                if success {
                    strongSelf.showEmptyView(strongSelf.total < 1)
                }

                strongSelf.updateNavBar()
            }
        }
    }

    func add(entity: Any, open: Bool = true) {
        guard let provider = provider else { return }

        if let file = entity as? ASCFile {
            provider.add(item: file, at: 0)

            provider.updateSort { provider, currentFolder, success, error in
                self.tableView.reloadData()
                self.showEmptyView(self.total < 1)

                if let index = self.tableData.firstIndex(where: { $0.id == file.id }) {
                    if ASCAppSettings.Feature.hideSearchbarIfEmpty {
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
                let isDocument = fileExt == ASCConstants.FileExtensions.docx
                let isSpreadsheet = fileExt == ASCConstants.FileExtensions.xlsx
                let isPresentation = fileExt == ASCConstants.FileExtensions.pptx

                if isDocument || isSpreadsheet || isPresentation {
                    provider.open(file: file, openMode: .create, canEdit: true)
                }
            }
        } else if let folder = entity as? ASCFolder {
            provider.add(item: folder, at: 0)

            provider.updateSort { provider, currentFolder, success, error in
                self.tableView.reloadData()

                self.showEmptyView(self.total < 1)

                if let index = self.tableData.firstIndex(where: { $0.uid == folder.uid }) {
                    if ASCAppSettings.Feature.hideSearchbarIfEmpty {
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
                openFolder(folder: folder)
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

    func flashBlockInteration() {
        view.isUserInteractionEnabled = false
        ASCViewControllerManager.shared.rootController?.isUserInteractionEnabled = false
        delay(seconds: 0.2) {
            self.view.isUserInteractionEnabled = true
            ASCViewControllerManager.shared.rootController?.isUserInteractionEnabled = true
        }
    }

    @objc func onFilterAction() {
        let providerCopy = provider?.copy()
        provider?.filterController?.folder = folder
        provider?.filterController?.provider = providerCopy
        provider?.filterController?.onAction = { [weak self] in
            self?.loadFirstPage()
            self?.configureNavigationBar(animated: false)
        }
        provider?.filterController?.prepareForDisplay(total: total)

        if let filtersViewController = provider?.filterController?.filtersViewController {
            let navigationVC = UINavigationController(rootASCViewController: filtersViewController)

            if UIDevice.pad {
                navigationVC.preferredContentSize = CGSize(width: 380, height: 714)
                navigationVC.modalPresentationStyle = .popover
                navigationVC.popoverPresentationController?.barButtonItem = filterBarButton
                present(navigationVC, animated: true) {}
            } else {
                navigationController?.present(navigationVC, animated: true)
            }
        }
    }

    @objc func onAddEntityAction() {
        guard let provider = provider else { return }
        flashBlockInteration()
        ASCCreateEntity().showCreateController(for: provider, in: self, sender: addBarButton)
    }

    @objc func onActionSelect(_ sender: Any) {
        if #available(iOS 14.0, *) {
            if let button = sender as? UIButton {
                button.showsMenuAsPrimaryAction = true
                button.menu = correntFolderActionMenu(for: button)
            }
        } else {
            guard let folder, let sender = sender as? UIView else { return }
            let actionSheet = CurrentFolderMenu().actionSheet(for: folder, sender: sender, in: self)
            present(actionSheet, animated: true, completion: nil)
        }
    }

    @objc func onCancelAction() {
        setEditMode(false)
    }

    @objc func onSortAction(_ sender: Any) {
        if #available(iOS 14.0, *) {
            if let button = sender as? UIButton {
                button.showsMenuAsPrimaryAction = true
                button.menu = correntFolderActionMenu(for: button)
            }
        } else {
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
                        "order": ascending ? "ascending" : "descending",
                    ]

                    UserDefaults.standard.set(sortInfo, forKey: ASCConstants.SettingsKeys.sortDocuments)
                }
            }))
        }
    }

    @objc func onSelectAction() {
        guard view.isUserInteractionEnabled else { return }
        setEditMode(true)
        flashBlockInteration()
    }

    @objc func popViewController(gesture: UISwipeGestureRecognizer) {
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
        filterBarButton = createFilterBarButton()
        selectBarButton = selectBarButton
            ?? ASCStyles.createBarButton(image: Asset.Images.navSelect.image, target: self, action: #selector(onSelectAction))
        cancelBarButton = cancelBarButton
            ?? ASCStyles.createBarButton(title: ASCLocalization.Common.cancel, target: self, action: #selector(onCancelAction))
        selectAllBarButton = selectAllBarButton
            ?? ASCStyles.createBarButton(title: NSLocalizedString("Select", comment: "Button title"), target: self, action: #selector(onSelectAll))
        if let folder = folder,
           !folder.isRoom
        {
            sortSelectBarButton?.isEnabled = total > 0
        }
        sortBarButton?.isEnabled = total > 0
        selectBarButton?.isEnabled = total > 0
        selectAllBarButton?.isEnabled = total > 0
        filterBarButton?.isEnabled = total > 0 || provider?.filterController?.isReset == false

        if #available(iOS 14.0, *) {
            for barButton in [sortSelectBarButton, sortBarButton] {
                if let button = barButton?.customView as? UIButton {
                    button.showsMenuAsPrimaryAction = true
                    button.menu = correntFolderActionMenu(for: button)
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

            if let sortSelectBarBtn = sortSelectBarButton {
                rightBarBtnItems.append(sortSelectBarBtn)
            }

            if let filterBarBtn = filterBarButton, provider?.filterController != nil {
                rightBarBtnItems.append(filterBarBtn)
            }

            if let addBarBtn = addBarButton {
                rightBarBtnItems.append(addBarBtn)
            }

            navigationItem.setRightBarButtonItems(rightBarBtnItems, animated: animated)
        }

        if #available(iOS 11.0, *), featureLargeTitle {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .automatic
        }
    }

    private func createAddBarButton() -> UIBarButtonItem? {
        guard ((provider?.allowAdd(toFolder: folder)) != nil) && folder?.rootFolderType != .onlyofficeRoomArchived else { return nil }

        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)

        let icon: UIImage? = {
            guard folder?.isRoomListFolder == true else {
                return UIImage(systemName: "plus", withConfiguration: config)
            }
            return Asset.Images.barRectanglesAdd.image
        }()

        return ASCStyles.createBarButton(
            image: icon,
            target: self,
            action: #selector(onAddEntityAction)
        )
    }

    private func createFilterBarButton() -> UIBarButtonItem {
        let isReset = provider?.filterController?.isReset ?? true

        return ASCStyles.createBarButton(
            image: isReset ? Asset.Images.barFilter.image : Asset.Images.barFilterOn.image,
            target: self,
            action: #selector(onFilterAction)
        )
    }

    private func createSortSelectBarButton() -> UIBarButtonItem {
        guard categoryIsRecent else {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)

            return ASCStyles.createBarButton(
                image: UIImage(systemName: "ellipsis.circle", withConfiguration: config),
                target: self,
                action: #selector(onActionSelect)
            )
        }

        return ASCStyles.createBarButton(
            title: NSLocalizedString("Select", comment: "Navigation bar button title"),
            target: self,
            action: #selector(onSelectAction)
        )
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
        let isRoomList = folder.isRoomListFolder
        let isDevice = (provider?.id == ASCFileManager.localProvider.id)
        let isShared = folder.rootFolderType == .onlyofficeShare
        let isTrash = self.isTrash(folder)
        let isRecent = categoryIsRecent
        let isProjectRoot = (folder.rootFolderType == .onlyofficeBunch || folder.rootFolderType == .onlyofficeProjects) && isRoot
        let isGuest = ASCFileManager.onlyofficeProvider?.user?.isVisitor ?? false
        let isDocSpaceArchive = isRoomList && folder.rootFolderType == .onlyofficeRoomArchived
        let isDocSpaceArchiveRoomContent = folder.rootFolderType == .onlyofficeRoomArchived && !isRoot
        let isDocSpaceRoomShared = isRoomList && folder.rootFolderType == .onlyofficeRoomShared
        let isInfoShowing = (isDocSpaceRoomShared || isDocSpaceArchive) && selectedIds.count <= 1
        let isNeededUpdateToolBarOnSelection = isDocSpaceRoomShared || folder.isRoomListSubfolder
        let isNeededUpdateToolBarOnDeselection = isDocSpaceRoomShared || folder.isRoomListSubfolder

        events.removeListeners(eventNameToRemoveOrNil: "item:didSelect")
        events.removeListeners(eventNameToRemoveOrNil: "item:didDeselect")

        let fixedWidthButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let barIconSpacer = UIBarButtonItem(customView: fixedWidthButton)
        let barFlexSpacer: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let createBarButton: (_ image: UIImage, _ selector: Selector) -> UIBarButtonItem = { [weak self] image, selector in
            guard let strongSelf = self else { return UIBarButtonItem() }
            let buttonItem = ASCStyles.createBarButton(image: image, target: strongSelf, action: selector)

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

        // Move
        if !isTrash, !isDocSpaceArchive, !isDocSpaceArchiveRoomContent, !isDocSpaceRoomShared, isDevice || !(isShared || isProjectRoot || isGuest) {
            let addMoveBtnCompletion: () -> Void = { [self] in
                items.append(createBarButton(Asset.Images.barMove.image, #selector(onMoveSelected)))
                items.append(barFlexSpacer)
            }
            if folder.isRoomListSubfolder {
                canMoveAllSelectedItems() ? addMoveBtnCompletion() : nil
            } else {
                addMoveBtnCompletion()
            }
        }

        // Copy
        if !isTrash, !isRoomList {
            let addCopyBtnCompletion: () -> Void = { [self] in
                items.append(createBarButton(Asset.Images.barCopy.image, #selector(onCopySelected)))
                items.append(barFlexSpacer)
            }
            if folder.isRoomListSubfolder {
                canCopyAllSelectedItems() ? addCopyBtnCompletion() : nil
            } else {
                addCopyBtnCompletion()
            }
        }

        // Restore
        if isTrash {
            items.append(createBarButton(Asset.Images.barRecover.image, #selector(onMoveSelected)))
            items.append(barFlexSpacer)
        }

        // Restore room
        if isDocSpaceArchive, folder.security.move {
            items.append(createBarButton(Asset.Images.barRecover.image, #selector(onRoomRestore)))
            items.append(barFlexSpacer)
        }

        // Remove from list
        if isShared {
            items.append(createBarButton(Asset.Images.barDeleteLink.image, #selector(onTrashSelected)))
            items.append(barFlexSpacer)
        }

        // Remove
        if isDevice || !(isShared || isProjectRoot || isGuest || isRecent || isDocSpaceRoomShared || isDocSpaceArchiveRoomContent || isDocSpaceArchive) || (isDocSpaceArchive && canRemoveLeastOneItem()) {
            let addRemoveBtnCompletion: () -> Void = { [self] in
                items.append(createBarButton(Asset.Images.barDelete.image, #selector(onTrashSelected)))
                items.append(barFlexSpacer)
            }

            if folder.isRoomListSubfolder {
                canRemoveAllSelectedItems() ? addRemoveBtnCompletion() : nil
            } else {
                addRemoveBtnCompletion()
            }
        }

        // Info
        if isInfoShowing {
            items.append(createBarButton(Asset.Images.barInfo.image, #selector(onInfoSelected)))
            items.append(barFlexSpacer)
        }

        // Pin
        if isDocSpaceRoomShared {
            if !isInfoShowing {
                items.append(barIconSpacer)
                items.append(barFlexSpacer)
            }
            let icon = isSelectedItemsPinned() ? Asset.Images.barUnpin.image : Asset.Images.barPin.image
            items.append(createBarButton(icon, #selector(onPinSelected)))
            items.append(barFlexSpacer)
        }

        // Archive
        if isDocSpaceRoomShared {
            items.append(createBarButton(Asset.Images.barArchive.image, #selector(onArchiveSelected)))
            items.append(barFlexSpacer)
        }

        // Remove all
        if isTrash {
            items.append(UIBarButtonItem(image: Asset.Images.barDeleteAll.image, style: .plain, target: self, action: #selector(onEmptyTrashSelected)))
            items.append(barFlexSpacer)
        }

        // Remove all rooms
        if isDocSpaceArchive, canRemoveAllItems() {
            items.append(UIBarButtonItem(image: Asset.Images.barDeleteAll.image, style: .plain, target: self, action: #selector(onRemoveAllArchivedRooms)))
            items.append(barFlexSpacer)
        }

        if items.count > 1 {
            items.removeLast()
        }

        events.listenTo(eventName: "item:didSelect") { [weak self] in
            self?.updateSelectedInfo()
            if isNeededUpdateToolBarOnSelection {
                self?.configureToolBar()
            }
        }
        events.listenTo(eventName: "item:didDeselect") { [weak self] in
            self?.updateSelectedInfo()
            if isNeededUpdateToolBarOnDeselection {
                self?.configureToolBar()
            }
        }

        setToolbarItems(items, animated: false)
    }

    private func updateSelectedInfo() {
        let fileCount = tableData
            .filter { $0 is ASCFile }
            .filter { selectedIds.contains($0.uid) }
            .count
        let folderCount = tableData
            .filter { $0 is ASCFolder }
            .filter { selectedIds.contains($0.uid) }
            .count

        if fileCount + folderCount > 0 {
            if UIDevice.phone {
                title = String(format: NSLocalizedString("Selected: %ld", comment: ""), fileCount + folderCount)
            } else {
                if folderCount > 0, fileCount > 0 {
                    title = String.localizedStringWithFormat(NSLocalizedString("%lu Folder and %lu File selected", comment: ""), folderCount, fileCount)
                } else if folderCount > 0 {
                    title = String.localizedStringWithFormat(NSLocalizedString("%lu Folder selected", comment: ""), folderCount)
                } else if fileCount > 0 {
                    title = String.localizedStringWithFormat(NSLocalizedString("%lu File selected", comment: ""), fileCount)
                } else {
                    title = folder?.title
                }
            }
        } else {
            title = folder?.title
        }
    }

    private func isSelectedItemsPinned() -> Bool {
        guard selectedIds.count > 0 else { return false }
        return tableData
            .filter { selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFolder }
            .reduce(true) { partialResult, folder in
                partialResult && folder.pinned
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

    func setEditMode(_ edit: Bool) {
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

    private func fetchLocalData(_ completeon: ((Bool) -> Void)? = nil) {
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
                "text": searchValue,
            ]
        }

        // Filters
        if let filtersParams = provider?.filterController?.filtersParams {
            params["filters"] = filtersParams
        }

        provider?.fetch(for: folder, parameters: params) { [weak self] provider, folder, success, error in
            guard let strongSelf = self else { return }

            strongSelf.tableView.reloadData()
            strongSelf.showEmptyView(strongSelf.total < 1)

            completeon?(true)
        }
    }

    private func fetchCloudData(_ completeon: ((Bool) -> Void)? = nil) {
        guard let folder = folder else {
            completeon?(false)
            return
        }

        if let cloudProvider = provider {
            var params: [String: Any] = [:]

            // Search
            if searchController.isActive, let searchValue = searchValue {
                params["search"] = [
                    "text": searchValue,
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

            if let filtersParams = provider?.filterController?.filtersParams {
                params["filters"] = filtersParams
            }

            cloudProvider.fetch(for: folder, parameters: params) { [weak self] provider, entity, success, error in
                guard
                    let strongSelf = self,
                    let folder = entity as? ASCFolder
                else { return }

                let isCanceled: Bool = {
                    guard let error = error as? NetworkingError, case NetworkingError.cancelled = error else {
                        return false
                    }
                    return true
                }()

                if !isCanceled {
                    strongSelf.showErrorView(!success, error)
                }

                if success || isCanceled {
                    strongSelf.folder = folder
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

        if ASCAppSettings.Feature.hideSearchbarIfEmpty {
            searchController.searchBar.isHidden = true
        }

        addBarButton?.isEnabled = false // Disable create entity while loading first page

        fetchData { [weak self] success in
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
                if !success &&
                    strongSelf.folder?.rootFolderType != .deviceDocuments &&
                    !ASCNetworkReachability.shared.isReachable &&
                    OnlyofficeApiClient.shared.token != nil
                {
                    ASCBanner.shared.showError(
                        title: NSLocalizedString("No network", comment: ""),
                        message: NSLocalizedString("Check your internet connection", comment: "")
                    )
                }
            }
        }
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

        } else {
            loadingView.removeFromSuperview()
        }
    }

    private func showEmptyView(_ show: Bool) {
        if ASCAppSettings.Feature.hideSearchbarIfEmpty {
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
                if let index = provider?.items.firstIndex(where: { ($0 as? ASCFile)?.id == file.id }) {
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

        if let topVC = ASCViewControllerManager.shared.rootController?.topMostViewController(),
           topVC is ASCCreateEntityUIViewController
        {
            topVC.dismiss(animated: false, completion: nil)
        }

        // Cancel search
        searchController.searchBar.resignFirstResponder()
        searchController.isActive = false
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
        if !ASCViewControllerManager.shared.phoneLayout {
            setEditMode(false)
        }
    }

    @objc
    private func onAppDidEnterBackground() {
        searchController.isActive = false
    }

    private func updateNavBar() {
        let hasError = errorView?.superview != nil

        addBarButton?.isEnabled = !hasError && provider?.allowAdd(toFolder: folder) ?? false
        sortSelectBarButton?.isEnabled = !hasError && provider?.allowAdd(toFolder: folder) ?? false
        sortBarButton?.isEnabled = !hasError && total > 0
        selectBarButton?.isEnabled = !hasError && total > 0
        filterBarButton?.isEnabled = !hasError && total > 0
    }

    @available(iOS 14.0, *)
    private func correntFolderActionMenu(for button: UIButton) -> UIMenu? {
        guard let folder else { return nil }
        return CurrentFolderMenu().contextMenu(for: folder, in: self)
    }

    @available(iOS 14.0, *)
    private func selectAllMenu() -> UIMenu? {
        let uiActions: [UIAction] = {
            var uiActions = [UIAction]()
            uiActions.append(UIAction(
                title: NSLocalizedString("All", comment: ""),
                image: UIImage(systemName: "checkmark.circle"),
                handler: { [weak self] action in
                    self?.selectAllItems(type: AnyObject.self)
                }
            ))

            provider?.contentTypes.forEach { contentType in
                switch contentType {
                case .files:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Files", comment: ""),
                        image: Asset.Images.menuFiles.image,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFile.self)
                        }
                    ))
                case .folders:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Folders", comment: ""),
                        image: UIImage(systemName: "folder"),
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self)
                        }
                    ))
                case .documents:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Documents", comment: ""),
                        image: Asset.Images.menuDocuments.image,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.documents)
                        }
                    ))
                case .spreadsheets:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Spreadsheets", comment: ""),
                        image: Asset.Images.menuSpreadsheet.image,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.spreadsheets)
                        }
                    ))
                case .presentations:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Presentations", comment: ""),
                        image: Asset.Images.menuPresentation.image,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.presentations)
                        }
                    ))
                case .images:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Images", comment: ""),
                        image: UIImage(systemName: "photo"),
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.images)
                        }
                    ))
                case .public:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Public", comment: ""),
                        image: nil,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self, roomTypes: [.public])
                        }
                    ))
                case .collaboration:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Collaboration", comment: ""),
                        image: nil,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self, roomTypes: [.colobaration])
                        }
                    ))
                case .custom:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Custom", comment: ""),
                        image: nil,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self, roomTypes: [.custom])
                        }
                    ))
                case .viewOnly:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("View-only", comment: ""),
                        image: nil,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self, roomTypes: [.viewOnly])
                        }
                    ))
                case .fillingForms:
                    uiActions.append(UIAction(
                        title: NSLocalizedString("Filling form", comment: ""),
                        image: nil,
                        handler: { [weak self] action in
                            self?.selectAllItems(type: ASCFolder.self, roomTypes: [.fillingForm])
                        }
                    ))
                }
            }

            return uiActions
        }()

        return UIMenu(title: "", options: .displayInline, children: uiActions)
    }

    private func highlight(cell: UITableViewCell) {
        let originalBgColor = cell.contentView.backgroundColor

        let highlightView = UIView(frame: CGRect(
            x: -100,
            y: 0,
            width: cell.contentView.width + 200,
            height: cell.contentView.height
        )
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
            if let index = tableData.firstIndex(where: { ($0 as? ASCFile)?.id == file.id }) {
                return IndexPath(row: index, section: 0)
            }
        } else if let folder = entity as? ASCFolder {
            if let index = tableData.firstIndex(where: { ($0 as? ASCFolder)?.id == folder.id }) {
                return IndexPath(row: index, section: 0)
            }
        }

        return nil
    }

    private func isTrash(_ folder: ASCFolder?) -> Bool {
        return folder?.rootFolderType == .onlyofficeTrash || folder?.rootFolderType == .deviceTrash
    }

    private func configureSwipeGesture() {
        let swipeToPreviousFolder = UISwipeGestureRecognizer(target: self, action: #selector(popViewController))
        swipeToPreviousFolder.direction = .right
        swipeToPreviousFolder.name = "swipeRight"
        view.addGestureRecognizer(swipeToPreviousFolder)
    }

    // MARK: - Open files

    func open(file: ASCFile, viewMode: Bool = false) {
        let title = file.title,
            fileExt = title.fileExtension().lowercased(),
            allowOpen = ASCConstants.FileExtensions.allowEdit.contains(fileExt)

        if isTrash(folder) {
            UIAlertController.showWarning(
                in: self,
                message: NSLocalizedString("The file in the Trash can not be viewed.", comment: "")
            )
            return
        }

        if allowOpen {
            provider?.delegate = self
            provider?.open(file: file, openMode: viewMode ? .view : .edit, canEdit: provider?.allowEdit(entity: file) ?? false)
            searchController.isActive = false
        } else if let index = tableData.firstIndex(where: { $0.id == file.id }) {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
            provider?.delegate = self
            provider?.preview(file: file, files: (tableData.filter { $0 is ASCFile }) as? [ASCFile], in: cell)
        }

        // Reset as New
        if let fileIndex = tableData.firstIndex(where: { $0.id == file.id }) {
            (tableData[fileIndex] as? ASCFile)?.isNew = false
            tableView.beginUpdates()
            tableView.reloadRows(at: [IndexPath(row: fileIndex, section: 0)], with: .none)
            tableView.endUpdates()
        }
    }

    func checkUnsuccessfullyOpenedFile() {
        ASCEditorManager.shared.checkUnsuccessfullyOpenedFile(parent: self)
    }

    // MARK: - Entity actions

    func openFolder(folder: ASCFolder) {
        let controller = ASCDocumentsViewController.instantiate(from: Storyboard.main)
        navigationController?.pushViewController(controller, animated: true)

        controller.provider = provider?.copy()
        controller.provider?.cancel()
        controller.provider?.reset()
        controller.folder = folder
        controller.title = folder.title
    }

    func delete(cell: UITableViewCell) {
        if let fileCell = cell as? ASCFileCell, let file = fileCell.file {
            removerActionController.delete(indexes: [file.uid])
        } else if let folderCell = cell as? ASCFolderCell, let folder = folderCell.folder {
            if folder.rootFolderType == .onlyofficeRoomArchived {
                deleteArchive(folder: folder)
            } else {
                removerActionController.delete(indexes: [folder.uid])
            }
        }
    }

    func deleteArchive(folder: ASCFolder) {
        let alertController = UIAlertController(title: NSLocalizedString("Delete forever?", comment: ""), message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel, handler: nil)

        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { _ in
            self.removerActionController.delete(indexes: [folder.uid])
        }
        alertController.message = NSLocalizedString("You are about to delete this room. You won’t be able to restore them.", comment: "")

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    func rename(cell: UITableViewCell) {
        guard let provider = provider else { return }

        var file: ASCFile?
        var folder: ASCFolder?

        if let fileCell = cell as? ASCFileCell {
            file = fileCell.file
        } else if let folderCell = cell as? ASCFolderCell {
            folder = folderCell.folder
        }

        var hud: MBProgressHUD?

        ASCEntityManager.shared.rename(for: provider, entity: file ?? folder) { [unowned self] status, entity, error in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.mode = .indeterminate
                hud?.label.text = NSLocalizedString("Renaming", comment: "Caption of the processing")
            } else if status == .error {
                hud?.hide(animated: true)

                if let error {
                    UIAlertController.showError(in: self, message: error.localizedDescription)
                }
            } else if status == .end {
                if entity != nil {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: 1.3)

                    let file = entity as? ASCFile
                    let folder = entity as? ASCFolder

                    if let indexPath = self.tableView.indexPath(for: cell), let entity: ASCEntity = file ?? folder {
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

    func archive(cell: UITableViewCell?, folder: ASCFolder) {
        let processLabel: String = NSLocalizedString("Archiving", comment: "Caption of the processing")
        if let cell = cell {
            handleAction(folder: folder, action: .archive, processingLabel: processLabel, copmletionBehavior: .delete(cell))
        } else {
            handleAction(folder: folder, action: .archive, processingLabel: processLabel, copmletionBehavior: .archiveAction)
        }
    }

    func unarchive(cell: UITableViewCell?, folder: ASCFolder) {
        let processLabel: String = NSLocalizedString("Moving from archive", comment: "Caption of the processing")
        if let cell = cell {
            handleAction(folder: folder, action: .unarchive, processingLabel: processLabel, copmletionBehavior: .delete(cell))
        } else {
            handleAction(folder: folder, action: .unarchive, processingLabel: processLabel, copmletionBehavior: .archiveAction)
        }
    }

    private func handleAction(folder: ASCFolder, action: ASCEntityActions, processingLabel: String, copmletionBehavior: CompletionBehavior) {
        let hud = MBProgressHUD.showTopMost()
        hud?.isHidden = false
        provider?.handle(action: action, folder: folder) { [weak self] status, entity, error in
            guard let self = self else {
                hud?.hide(animated: false)
                return
            }
            self.baseProcessHandler(hud: hud, processingMessage: processingLabel, status, entity, error) {
                if entity != nil {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: 1.3)
                    switch copmletionBehavior {
                    case let .delete(cell):
                        if let indexPath = self.tableView.indexPath(for: cell), entity as? ASCFolder != nil {
                            self.provider?.remove(at: indexPath.row)
                            self.tableView.beginUpdates()
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                            self.tableView.endUpdates()
                        }
                    case .archiveAction:
                        if let previousController = self.navigationController?.viewControllers[1] as? ASCDocumentsViewController,
                           let folderItem = previousController.tableView.visibleCells.compactMap({ $0 as? ASCFolderCell }).first(where: { $0.folder?.title == folder.title }),
                           let indexPath = previousController.tableView.indexPath(for: folderItem)
                        {
                            previousController.provider?.remove(at: indexPath.row)
                            previousController.tableView.beginUpdates()
                            previousController.tableView.deleteRows(at: [indexPath], with: .fade)
                            previousController.tableView.endUpdates()

                            if let refreshControl = previousController.refreshControl {
                                previousController.refresh(refreshControl)
                            }

                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }

    func pinToggle(cell: UITableViewCell) {
        guard let folderCell = cell as? ASCFolderCell,
              let folder = folderCell.folder,
              let provider = provider else { return }
        let hud = MBProgressHUD.showTopMost()
        hud?.isHidden = false
        let action: ASCEntityActions = folder.pinned ? .unpin : .pin
        let processLabel: String = folder.pinned
            ? NSLocalizedString("Unpinning", comment: "Caption of the processing")
            : NSLocalizedString("Pinning", comment: "Caption of the processing")
        provider.handle(action: action, folder: folder) { [weak self] status, entity, error in
            guard let self = self else {
                hud?.hide(animated: false)
                return
            }
            self.baseProcessHandler(hud: hud, processingMessage: processLabel, status, entity, error) {
                if entity != nil {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: 1.3)
                    self.loadFirstPage()
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }

    func baseProcessHandler(hud: MBProgressHUD?,
                            processingMessage: String,
                            _ status: ASCEntityProcessStatus,
                            _ result: Any?,
                            _ error: Error?,
                            completion: () -> Void)
    {
        if status == .begin {
            hud?.isHidden = false
            hud?.mode = .indeterminate
            hud?.label.text = processingMessage
        } else if status == .error {
            hud?.hide(animated: true)
            if let error {
                UIAlertController.showError(in: self, message: error.localizedDescription)
            }
        } else if status == .end {
            completion()
        }
    }

    func download(cell: UITableViewCell) {
        if cell is ASCFileCell {
            downloadFile(cell: cell)
        } else if cell is ASCFolderCell {
            let folderCell = cell as! ASCFolderCell
            downloadFolder(cell: cell, folder: folderCell.folder!)
        }
    }

    func downloadFile(cell: UITableViewCell) {
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
            handler: { cancel in
                forceCancel = cancel
            }
        )

        ASCEntityManager.shared.download(for: provider, entity: file) { [unowned self] status, progress, result, error, cancel in
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
                        message: error?.localizedDescription ?? NSLocalizedString("Could not download file.", comment: "")
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

    func downloadFolder(cell: UITableViewCell?, folder: ASCFolder) {
        guard let provider = provider as? ASCOnlyofficeProvider
        else { return }

        let transferAlert = ASCProgressAlert(
            title: NSLocalizedString("Downloading", comment: "Caption of the processing"),
            message: nil,
            handler: { cancel in
                if cancel {
                    provider.apiClient.request(OnlyofficeAPI.Endpoints.Operations.terminate)
                    provider.cancel()
                    log.warning("Active operations canceled")
                }
            }
        )

        transferAlert.show()

        provider.download(items: [folder]) { progress in
            transferAlert.progress = progress
        } completion: { [weak self] result in
            switch result {
            case let .success(url):
                transferAlert.hide {
                    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

                    if UIDevice.pad {
                        if let cell = cell {
                            activityViewController.popoverPresentationController?.sourceView = cell
                            activityViewController.popoverPresentationController?.sourceRect = cell.bounds
                        } else {
                            activityViewController.popoverPresentationController?.sourceView = self?.sortSelectBarButton?.customView
                            activityViewController.popoverPresentationController?.sourceRect = (self?.sortSelectBarButton?.customView!.bounds)!
                        }
                    }

                    self?.present(activityViewController, animated: true, completion: nil)
                }
            case let .failure(error):
                transferAlert.hide()
                log.error(error)

                if let self {
                    UIAlertController.showError(
                        in: self,
                        message: NSLocalizedString("Couldn't download the room.", comment: "")
                    )
                }
            }
        }
    }

    func leaveRoom(cell: UITableViewCell?, folder: ASCFolder) {
        guard let provider = provider as? ASCOnlyofficeProvider
        else { return }

        var hud: MBProgressHUD?

        let isOwner: Bool = provider.checkRoomOwner(folder: folder)
        let alertController = UIAlertController(title: NSLocalizedString("Leave the room", comment: ""), message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel, handler: nil)

        if isOwner {
            let assignOwnerAction = UIAlertAction(title: NSLocalizedString("Assign Owner", comment: ""), style: .default) { _ in
                self.navigator.navigate(to: .leaveRoom(entity: folder) { status, result, error in
                    if status == .begin {
                        hud = MBProgressHUD.showTopMost()
                    } else if status == .error {
                        hud?.hide(animated: true)
                        UIAlertController.showError(
                            in: self,
                            message: NSLocalizedString("Couldn't leave the room", comment: "")
                        )
                    } else if status == .end {
                        hud?.setSuccessState()
                        hud?.label.numberOfLines = 0
                        hud?.label.text = NSLocalizedString("You have left the room and appointed a new owner", comment: "")
                        if let cell = cell {
                            if let indexPath = self.tableView.indexPath(for: cell) {
                                self.provider?.remove(at: indexPath.row)
                                self.tableView.beginUpdates()
                                self.tableView.deleteRows(at: [indexPath], with: .fade)
                                self.tableView.endUpdates()
                                if let refreshControl = self.refreshControl {
                                    self.refresh(refreshControl)
                                }
                            }
                        } else {
                            if let previousController = self.navigationController?.viewControllers[1] as? ASCDocumentsViewController,
                               let folderItem = previousController.tableView.visibleCells.compactMap({ $0 as? ASCFolderCell }).first(where: { $0.folder?.title == folder.title }),
                               let indexPath = previousController.tableView.indexPath(for: folderItem)
                            {
                                previousController.provider?.remove(at: indexPath.row)
                                previousController.tableView.beginUpdates()
                                previousController.tableView.deleteRows(at: [indexPath], with: .fade)
                                previousController.tableView.endUpdates()

                                if let refreshControl = previousController.refreshControl {
                                    previousController.refresh(refreshControl)
                                }

                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                        hud?.hide(animated: false, afterDelay: 1.3)
                    }
                })
            }
            alertController.message = NSLocalizedString("You are the owner of this room. Before you leave the room, you must transfer the owner’s role to another user.", comment: "")

            alertController.addAction(assignOwnerAction)

        } else {
            let submitAction = UIAlertAction(title: ASCLocalization.Common.ok, style: .default) { _ in
                provider.leaveRoom(folder: folder) { status, result, error in
                    if status == .begin {
                        hud = MBProgressHUD.showTopMost()
                    } else if status == .error {
                        hud?.hide(animated: true)
                        UIAlertController.showError(
                            in: self,
                            message: NSLocalizedString("Couldn't leave the room", comment: "")
                        )
                    } else if status == .end {
                        hud?.setSuccessState()
                        hud?.label.text = NSLocalizedString("You have left the room", comment: "")
                        if let cell = cell {
                            if let indexPath = self.tableView.indexPath(for: cell) {
                                self.provider?.remove(at: indexPath.row)
                                self.tableView.beginUpdates()
                                self.tableView.deleteRows(at: [indexPath], with: .fade)
                                self.tableView.endUpdates()
                                if let refreshControl = self.refreshControl {
                                    self.refresh(refreshControl)
                                }
                            }
                        } else {
                            self.navigationController?.popViewController(animated: true)
                            if let refreshControl = self.refreshControl {
                                self.refresh(refreshControl)
                            }
                        }
                        hud?.hide(animated: false, afterDelay: 1.3)
                    }
                }
            }

            alertController.message = NSLocalizedString("Do you really want to leave this room? You will be able to join it again via new invitation by a room admin.", comment: "")

            alertController.addAction(submitAction)
        }

        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    func editRoom(folder: ASCFolder) {
        let vc = EditRoomViewController(folder: folder) { _ in
            if let refreshControl = self.refreshControl {
                self.refresh(refreshControl)
                if let viewControllers = self.navigationController?.viewControllers,
                   let index = viewControllers.firstIndex(of: self),
                   index > 0
                {
                    let previousController = viewControllers[index - 1] as? ASCDocumentsViewController
                    previousController?.refresh(refreshControl)
                }
            }
        }

        vc.modalPresentationStyle = .formSheet
        vc.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize

        present(vc, animated: true, completion: nil)
    }

    func favorite(cell: UITableViewCell, favorite: Bool) {
        guard
            let provider = provider,
            let fileCell = cell as? ASCFileCell,
            let file = fileCell.file
        else { return }

        var hud: MBProgressHUD?

        ASCEntityManager.shared.favorite(for: provider, entity: file, favorite: favorite) { [unowned self] status, entity, error in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.mode = .indeterminate
            } else if status == .error {
                hud?.hide(animated: true)

                if let error {
                    UIAlertController.showError(in: self, message: error.localizedDescription)
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

                    if categoryIsFavorite, !favorite {
                        showEmptyView(total < 1)
                    }
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }

    func markAsRead(cell: UITableViewCell) {
        guard
            let provider = provider,
            let entity = (cell as? ASCFileCell)?.file ?? (cell as? ASCFolderCell)?.folder
        else { return }

        var hud: MBProgressHUD?

        ASCEntityManager.shared.markAsRead(for: provider, entities: [entity]) { [unowned self] status, result, error in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.mode = .indeterminate
            } else if status == .error {
                hud?.hide(animated: true)

                if let error {
                    UIAlertController.showError(in: self, message: error.localizedDescription)
                }
            } else if status == .end {
                if let entities = result as? [AnyObject], let entity = entities.first {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: 1.3)

                    if let indexPath = self.tableView.indexPath(for: cell) {
                        if let file = entity as? ASCFile {
                            file.isNew = false
                            self.provider?.items[indexPath.row] = file
                        } else if let folder = entity as? ASCFolder {
                            folder.new = 0
                            self.provider?.items[indexPath.row] = folder
                        }

                        self.tableView.beginUpdates()
                        self.tableView.reloadRows(at: [indexPath], with: .fade)
                        self.tableView.endUpdates()
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
                handler: { cancel in
                    forceCancel = cancel
                }
            )

            openingAlert.show()

            let destinationPath = Path.userTemporary + file.title

            provider?.download(file.viewUrl ?? "", to: URL(fileURLWithPath: destinationPath.rawValue)) { [weak self] result, progress, error in
                openingAlert.progress = Float(progress)

                if forceCancel {
                    self?.provider?.cancel()
                    return
                }

                guard let strongSelf = self else { return }

                if error != nil {
                    openingAlert.hide()
                    UIAlertController.showError(
                        in: strongSelf,
                        message: NSLocalizedString("Could not download the file.", comment: "")
                    )
                } else if result != nil {
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

        var hud: MBProgressHUD?

        ASCEntityManager.shared.duplicate(file: file, to: folder) { [unowned self] status, progress, result, error, cancel in
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
                    message: error?.localizedDescription ?? NSLocalizedString("Could not duplicate the file.", comment: "")
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
                } else {
                    loadFirstPage()
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

    func more(cell: UITableViewCell, menuButton: UIButton) {
        if let moreAlertController = buildActionMenu(for: cell) {
            if UIDevice.pad {
                moreAlertController.modalPresentationStyle = .popover
                moreAlertController.popoverPresentationController?.sourceView = menuButton
                moreAlertController.popoverPresentationController?.sourceRect = menuButton.bounds
                moreAlertController.popoverPresentationController?.permittedArrowDirections = [.up, .down]
                flashBlockInteration()
            }

            moreAlertController.view.tintColor = view.tintColor
            searchController.searchBar.resignFirstResponder()
            present(moreAlertController, animated: true, completion: nil)
            hideableViewControllerOnTransition = moreAlertController
        }
    }

    private func insideTransfer(
        items: [ASCEntity],
        to folder: ASCFolder,
        move: Bool = false,
        overwride: Bool = false,
        completion: ((MovedEntities?) -> Void)? = nil
    ) {
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
            handler: { status, progress, result, error, cancel in
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
                        message: error?.localizedDescription ?? NSLocalizedString("Could not copy.", comment: "")
                    )
                    completion?(nil)
                } else if status == .end {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: 1.3)

                    completion?(items)
                }
            }
        )
    }

    private func insideCheckTransfer(
        items: [ASCEntity],
        to folder: ASCFolder,
        move: Bool = false,
        complation: @escaping ((_ overwride: Bool, _ cancel: Bool) -> Void)
    ) {
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
                    message: error?.localizedDescription ?? NSLocalizedString("Could not copy.", comment: "")
                )
            } else if status == .end {
                hud?.hide(animated: false)

                if let conflicts = result as? [Any], conflicts.count > 0 {
                    let title = (conflicts.first as? ASCFolder)?.title ?? (conflicts.first as? ASCFile)?.title ?? ""
                    let message = conflicts.count > 1
                        ? String(format: NSLocalizedString("%lu items with the same name already exist in the folder '%@'. Overwrite the items?", comment: ""), conflicts.count, folder.title)
                        : String(format: NSLocalizedString("The item with the name '%@' already exists in the folder '%@'.", comment: ""), title, folder.title)

                    let alertController = UIAlertController(
                        title: NSLocalizedString("Overwrite confirmation", comment: "Button title"),
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
                            }
                        )
                    )

                    alertController.addAction(
                        UIAlertAction(
                            title: NSLocalizedString("Skip", comment: "Button title"),
                            style: .default,
                            handler: { action in
                                complation(false, false)
                            }
                        )
                    )

                    alertController.addAction(
                        UIAlertAction(
                            title: ASCLocalization.Common.cancel,
                            style: .cancel,
                            handler: { action in
                                complation(false, true)
                            }
                        )
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

        func transferViaManager(items: [ASCEntity], completion: ((UnmovedEntities?) -> Void)? = nil) {
            if items.count < 1 {
                completion?(nil)
                return
            }

            let transferNavigationVC = ASCTransferNavigationController.instantiate(from: Storyboard.transfer)

            if UIDevice.pad {
                transferNavigationVC.modalPresentationStyle = .formSheet
                transferNavigationVC.preferredContentSize = CGSize(width: ASCConstants.Size.defaultPreferredContentSize.width, height: 520)
            }

            present(transferNavigationVC, animated: true, completion: nil)

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
                    strongSelf.insideCheckTransfer(items: items, to: folder, move: move) { overwride, cancel in
                        guard !cancel else {
                            completion?(items)
                            return
                        }

                        strongSelf.insideTransfer(items: items, to: folder, move: move, overwride: overwride) { movedEntities in
                            guard movedEntities != nil else {
                                completion?(items)
                                return
                            }

                            completion?(nil)

                            if let destVC = getLoadedViewController(byFolderId: folder.id, andProviderId: provider.id) {
                                destVC.loadFirstPage()
                            }
                        }
                    }
                } else {
                    if let srcProvider = self?.provider,
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
                            handler: { cancel in
                                forceCancel = cancel
                            }
                        )

                        transferAlert.show()
                        transferAlert.progress = 0

                        ASCEntityManager.shared.transfer(
                            from: (items: items, provider: srcProvider),
                            to: (folder: destFolder, provider: destProvider),
                            move: move,
                            handler: { [weak self] progress, complate, success, newItems, error, cancel in
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
                            }
                        )
                    }
                }
            }

            if let transferViewController = transferNavigationVC.topViewController as? ASCTransferViewController {
                transferNavigationVC.transferType = isTrash(folder) ? .recover : (move ? .move : .copy)
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

        func insert(transferedItems items: [ASCEntity], toLoadedViewController viewController: ASCDocumentsViewController) {
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
            let response = loadedDocumentsViewControllerFinder.find(requestModel: request)

            guard let destinationVC = response.viewController else {
                return nil
            }

            return destinationVC
        }
    }

    func emptyTrash() {
        guard let provider = provider else { return }

        let hud = MBProgressHUD.showTopMost()
        hud?.mode = .annularDeterminate
        hud?.progress = 0
        hud?.label.text = NSLocalizedString("Cleanup", comment: "Caption of the processing")

        provider.emptyTrash(completeon: { [unowned self] provider, result, success, error in
            if let error = error {
                hud?.hide(animated: true)
                UIAlertController.showError(
                    in: self,
                    message: error.localizedDescription
                )
            } else {
                hud?.setSuccessState()
                hud?.hide(animated: false, afterDelay: 1.3)

                if self.isTrash(self.folder) || self.folder?.rootFolderType == .onlyofficeRoomArchived {
                    self.provider?.cancel()
                    self.provider?.reset()
                    self.tableView.reloadData()
                }

                self.showEmptyView(self.total < 1)
                self.updateNavBar()
                self.setEditMode(false)
            }
        })
    }

    func copyGeneralLinkToClipboard(room: ASCFolder) {
        if let onlyofficeProvider = provider as? ASCOnlyofficeProvider {
            let hud = MBProgressHUD.showTopMost()
            Task {
                let generalLinkResult = await onlyofficeProvider.generalLink(for: room)

                await MainActor.run {
                    switch generalLinkResult {
                    case let .success(link):
                        UIPasteboard.general.string = link
                        hud?.setState(result: .success(NSLocalizedString("Link successfully\ncopied to clipboard", comment: "Button title")))

                    case .failure:
                        hud?.setState(result: .failure(nil))
                    }

                    hud?.hide(animated: true, afterDelay: 1.3)
                }
            }
        }
    }

    private func selectAllItems<T>(type: T.Type, extensions: [String]? = nil, roomTypes: [ASCRoomType]? = nil) {
        if type == ASCFile.self {
            var files: [ASCEntity] = []
            if let extensions = extensions {
                files = tableData.filter { $0 is ASCFile && extensions.contains(($0 as? ASCFile)?.title.fileExtension().lowercased() ?? "") }
            } else {
                files = tableData.filter { $0 is ASCFile }
            }
            let selectedFiles = files.filter { selectedIds.contains($0.uid) }
            selectedIds = (
                (selectedFiles.count == selectedIds.count)
                    && (selectedFiles.count == files.count)
                    && selectedFiles.count > 0)
                ? []
                : Set(files.map { $0.uid }
                )
        } else if type == ASCFolder.self {
            let folders = tableData.filter {
                guard let folder = $0 as? ASCFolder else { return false }
                guard let roomTypes = roomTypes, let roomType = folder.roomType else {
                    return $0 is ASCFolder
                }
                return roomTypes.contains(roomType)
            }
            let selectedFolders = folders.filter { selectedIds.contains($0.uid) }
            selectedIds = (
                (selectedFolders.count == selectedIds.count)
                    && (selectedFolders.count == folders.count)
                    && selectedFolders.count > 0)
                ? []
                : Set(folders.map { $0.uid }
                )
        } else {
            selectedIds = selectedIds.count == tableData.count
                ? []
                : Set(tableData.map { $0.uid })
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

        provider?.contentTypes.forEach { contentType in
            switch contentType {
            case .files:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Files", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFile.self)
                }))
            case .folders:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Folders", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self)
                }))
            case .documents:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Documents", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.documents)
                }))
            case .spreadsheets:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Spreadsheets", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.spreadsheets)
                }))
            case .presentations:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Presentations", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.presentations)
                }))
            case .images:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Images", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFile.self, extensions: ASCConstants.FileExtensions.images)
                }))
            case .public:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Public", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self, roomTypes: [.public])
                }))
            case .collaboration:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Collaboration", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self, roomTypes: [.colobaration])
                }))
            case .custom:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Custom", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self, roomTypes: [.custom])
                }))
            case .viewOnly:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("View-only", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self, roomTypes: [.viewOnly])
                }))
            case .fillingForms:
                selectController.addAction(UIAlertAction(title: NSLocalizedString("Filling form", comment: ""), handler: { [weak self] action in
                    self?.selectAllItems(type: ASCFolder.self, roomTypes: [.fillingForm])
                }))
            }
        }

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

    @objc func onRoomRestore(_ sender: Any) {
        guard selectedIds.count > 0 else { return }
        tableData.filter { selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFolder }
            .forEach {
                guard let indexPath = indexPath(by: $0), let cell = tableView.cellForRow(at: indexPath) else { return }
                unarchive(cell: cell, folder: $0)
            }
        showEmptyView(total < 1)
        updateNavBar()
        setEditMode(false)
    }

    @objc func onRemoveAllArchivedRooms(_ sender: Any) {
        onTrash(ids: Set<String>(tableData.map { $0.uid }), sender, notificationType: .alert)
    }

    @objc func onTrashSelected(_ sender: Any) {
        onTrash(ids: selectedIds, sender, notificationType: .default)
    }

    private func canRemoveLeastOneItem() -> Bool {
        canPerformActionOnLeastOneItem(fileKeyPathSecurity: \.delete, folderKeyPathSecurity: \.delete)
    }

    private func canCopyLeastOneItem() -> Bool {
        canPerformActionOnLeastOneItem(fileKeyPathSecurity: \.copy, folderKeyPathSecurity: \.copy)
    }

    private func canMoveLeastOneItem() -> Bool {
        canPerformActionOnLeastOneItem(fileKeyPathSecurity: \.move, folderKeyPathSecurity: \.move)
    }

    private func canPerformActionOnLeastOneItem(fileKeyPathSecurity: KeyPath<ASCFileSecurity, Bool>,
                                                folderKeyPathSecurity: KeyPath<ASCFolderSecurity, Bool>) -> Bool
    {
        let folders = tableData.compactMap { $0 as? ASCFolder }
        let files = tableData.compactMap { $0 as? ASCFile }
        return folders.contains(where: { $0.security[keyPath: folderKeyPathSecurity] })
            || files.contains(where: { $0.security[keyPath: fileKeyPathSecurity] })
    }

    private func canRemoveAllItems() -> Bool {
        let canRemoveAllFolders: Bool = tableData.compactMap { $0 as? ASCFolder }.reduce(true) { partialResult, folder in
            partialResult && folder.security.delete
        }
        let canRemoveAllFiles = tableData.compactMap { $0 as? ASCFile }.reduce(true) { partialResult, file in
            partialResult && file.security.delete
        }
        return canRemoveAllFolders && canRemoveAllFiles
    }

    private func canRemoveAllSelectedItems() -> Bool {
        guard selectedIds.count > 0 else { return canRemoveLeastOneItem() }
        return canPerformActionOnSelectedItems(fileKeyPathSecurity: \.delete, folderKeyPathSecurity: \.delete)
    }

    private func canCopyAllSelectedItems() -> Bool {
        guard selectedIds.count > 0 else { return canCopyLeastOneItem() }
        return canPerformActionOnSelectedItems(fileKeyPathSecurity: \.copy, folderKeyPathSecurity: \.copy)
    }

    private func canMoveAllSelectedItems() -> Bool {
        guard selectedIds.count > 0 else { return canMoveLeastOneItem() }
        return canPerformActionOnSelectedItems(fileKeyPathSecurity: \.move, folderKeyPathSecurity: \.move)
    }

    private func canPerformActionOnSelectedItems(fileKeyPathSecurity: KeyPath<ASCFileSecurity, Bool>,
                                                 folderKeyPathSecurity: KeyPath<ASCFolderSecurity, Bool>) -> Bool
    {
        guard selectedIds.count > 0 else { return true }
        let canPerformActionOnFolders = tableData.filter { selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFolder }
            .reduce(true) { partialResult, folder in
                folder.security[keyPath: folderKeyPathSecurity] && partialResult
            }
        let canPerformActionOnFiles = tableData.filter { selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFile }
            .reduce(true) { partialResult, file in
                file.security[keyPath: fileKeyPathSecurity] && partialResult
            }
        return canPerformActionOnFolders && canPerformActionOnFiles
    }

    private func onTrash(ids: Set<String>, _ sender: Any, notificationType: NotificationType) {
        guard view.isUserInteractionEnabled else { return }

        if ids.count > 0 {
            let selectetItems = tableData.filter { ids.contains($0.uid) }
            let folderCount = selectetItems.filter { $0 is ASCFolder }.count
            let fileCount = selectetItems.filter { $0 is ASCFile }.count

            switch notificationType {
            case .default:
                showDeafultRomoveNotification(folderCount: folderCount, fileCount: fileCount, sender: sender) { [unowned self] in
                    self.removerActionController.delete(indexes: ids)
                }
            case .alert:
                showRemoveAlert { [unowned self] in
                    self.removerActionController.delete(indexes: ids)
                }
            }
        }
    }

    @objc func onInfoSelected(_ sender: Any) {
        guard let provider = provider, let folder = folder, selectedIds.count == 1 else { return }
        presentShareController(provider: provider, entity: folder)
    }

    @objc func onPinSelected(_ sender: Any) {
        guard let provider = provider, selectedIds.count > 0 else { return }

        let dispatchGroup = DispatchGroup()
        var indexPathes: [IndexPath] = []
        let hud = MBProgressHUD.showTopMost()
        let isSelectedItemsPinned = isSelectedItemsPinned()
        let action: ASCEntityActions = isSelectedItemsPinned ? .unpin : .pin
        hud?.label.text = isSelectedItemsPinned
            ? NSLocalizedString("Unpinning", comment: "Caption of the processing")
            : NSLocalizedString("Pinning", comment: "Caption of the processing")
        tableData.filter { selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFolder }
            .forEach {
                guard let indexPath = indexPath(by: $0) else { return }
                dispatchGroup.enter()
                provider.handle(action: action, folder: $0) { status, _, _ in
                    if status == .end {
                        indexPathes.append(indexPath)
                    }
                    if status == .end || status == .error {
                        dispatchGroup.leave()
                    }
                }
            }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.updateNavBar()
            self.setEditMode(false)
            hud?.hide(animated: true, afterDelay: 1)
            self.loadFirstPage()
        }
    }

    @objc func onArchiveSelected(_ sender: Any) {
        guard let provider = provider, selectedIds.count > 0 else { return }

        let dispatchGroup = DispatchGroup()
        var indexPathes: [IndexPath] = []
        let hud = MBProgressHUD.showTopMost()

        hud?.label.text = NSLocalizedString("Archiving", comment: "Caption of the processing")
        tableData.filter { selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFolder }
            .forEach {
                guard let indexPath = indexPath(by: $0) else { return }
                dispatchGroup.enter()
                provider.handle(action: .archive, folder: $0) { status, _, _ in
                    if status == .end {
                        indexPathes.append(indexPath)
                    }
                    if status == .end || status == .error {
                        dispatchGroup.leave()
                    }
                }
            }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.removedItems(indexPaths: indexPathes)
            self.showEmptyView(self.total < 1)
            self.updateNavBar()
            self.setEditMode(false)
            hud?.hide(animated: true, afterDelay: 1)
        }
    }

    private func showDeafultRomoveNotification(folderCount: Int, fileCount: Int, sender: Any, handler: @escaping () -> Void) {
        var message = NSLocalizedString("Delete", comment: "")
        if folderCount > 0, fileCount > 0 {
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
                title: message,
                style: .destructive,
                handler: { _ in
                    handler()
                }
            )
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

    private func showRemoveAlert(handler: @escaping () -> Void) {
        let alertDelete = UIAlertController(
            title: NSLocalizedString("Delete", comment: ""),
            message: NSLocalizedString("All items from Archived will be deleted forever. You won’t be able to restore them.", comment: ""),
            preferredStyle: .alert,
            tintColor: nil
        )

        alertDelete.addCancel()

        alertDelete.addAction(
            UIAlertAction(
                title: NSLocalizedString("Delete forever", comment: ""),
                style: .destructive,
                handler: { _ in
                    handler()
                }
            )
        )

        present(alertDelete, animated: true, completion: nil)
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

// MARK: - Table view data source

extension ASCDocumentsViewController {
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
                        folderCell.provider = provider
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
                UIAlertController.showWarning(
                    in: self,
                    message: NSLocalizedString("The folder in the Trash can not be opened.", comment: "")
                )
                return
            }

            openFolder(folder: folder)
        } else if let file = tableData[indexPath.row] as? ASCFile, let provider = provider {
            if ASCAppSettings.Feature.openViewModeByDefault {
                let title = file.title,
                    fileExt = title.fileExtension().lowercased()

                if ASCConstants.FileExtensions.documents.contains(fileExt) {
                    open(file: file, viewMode: true)
                } else {
                    open(file: file, viewMode: !(provider.allowEdit(entity: file) || provider.allowComment(entity: file)))
                }
            } else {
                open(file: file, viewMode: !provider.allowEdit(entity: file))
            }
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

            fetchData { [weak self] success in
                if !success {
                    guard let strongSelf = self else { return }

                    strongSelf.provider?.page -= 1
                    delay(seconds: 0.6) {
                        cell.isHidden = true
                    }
                }
            }
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
                return strongSelf.buildFileContextMenu(for: fileCell)
            } else if let folderCell = cell as? ASCFolderCell {
                return strongSelf.buildFolderContextMenu(for: folderCell)
            }

            return nil
        })
    }

    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        setEditMode(true)
        return true
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
        provider?.reset()
        tableView.reloadData()

        showLoadingPage(true)

        fetchData { [weak self] success in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }

                strongSelf.showLoadingPage(false)
                strongSelf.showErrorView(!success)

                if success {
                    strongSelf.showEmptyView(strongSelf.total < 1)
                }

                strongSelf.updateNavBar()
            }
        }
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

            fetchData { [weak self] success in
                DispatchQueue.main.async {
                    guard let strongSelf = self else { return }
                    strongSelf.updateNavBar()
                    strongSelf.events.trigger(eventName: "item:didSelect")
                }
            }
        }
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
//            log.info("Open file progress. Status: \(status), progress: \(progress), error: \(String(describing: error))")

            openingAlert.progress = progress

            if forceCancel {
                cancel = forceCancel
                self?.provider?.cancel()
                return
            }

            if status == .end || status == .error || status == .silentError {
                openingAlert.hide()

                if status == .error {
                    guard let self else { return }

                    UIAlertController.showError(
                        in: self,
                        message: error?.localizedDescription ?? NSLocalizedString("Could not open file.", comment: "")
                    )
                }
            }
        }

        return openHandler
    }

    func closeProgress(file: ASCFile, title: String) -> ASCEditorManagerCloseHandler {
        var hud: MBProgressHUD?

        let originalFile = file
        let closeHandler: ASCEditorManagerCloseHandler = { [weak self] status, progress, file, error, cancel in
            log.info("Close file progress. Status: \(status), progress: \(progress), error: \(String(describing: error))")

            if status == .begin {
                if hud == nil, file?.device == true {
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
                        if let index = strongSelf.tableData.firstIndex(where: { entity -> Bool in
                            guard let file = entity as? ASCFile else { return false }
                            return file.id == newFile.id || file.id == originalFile.id
                        }) {
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

    /// Helper function to present share screen from editors
    /// - Parameters:
    ///   - parent: Parent view controller
    ///   - entity: Entity to share
    private func presentShareController(in parent: UIViewController, entity: ASCEntity) {
        let sharedViewController = ASCSharingOptionsViewController(sourceViewController: self)
        let sharedNavigationVC = ASCBaseNavigationController(rootASCViewController: sharedViewController)

        sharedNavigationVC.modalPresentationStyle = .formSheet
        sharedNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize

        parent.present(sharedNavigationVC, animated: true, completion: nil)

        sharedViewController.setup(entity: entity)
        sharedViewController.requestToLoadRightHolders()
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
            "srcController": self,
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

        if let srcProvider = srcProvider,
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
                    handler: { cancel in
                        forceCancel = cancel
                    }
                )

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

                                    for index in 0 ..< newItems.count {
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

// MARK: - Remove handlers

extension ASCDocumentsViewController {
    func removeErrorHandler(error: String?) {
        UIAlertController.showError(in: self,
                                    message: error ?? NSLocalizedString("Could not delete.", comment: ""))
    }

    func removedItems(indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }

        // Remove data
        var newItemsData = provider?.items ?? []
        provider?.items = newItemsData.remove(indexes: indexPaths.map { $0.row })

        if let refreshControl = refreshControl {
            refresh(refreshControl)
        }
        showEmptyView(total < 1)
        updateNavBar()
        setEditMode(false)
    }

    func deleteIfNeeded(
        cell: UITableViewCell,
        menuButton: UIButton,
        complation: @escaping (UITableViewCell, Bool) -> Void
    ) {
        var title: String?
        let isTrash = self.isTrash(folder)
        let cellFolder = (cell as? ASCFolderCell)?.folder
        let currentFolder = folder

        if isTrash {
            title = NSLocalizedString("The file will be irretrievably deleted. This action is irreversible.", comment: "")
        } else if let currentFolder = currentFolder, currentFolder.isThirdParty {
            title = NSLocalizedString("Note: removal from your account can not be undone.", comment: "")
        }

        let alertDelete = UIAlertController(
            title: title,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )

        var message = NSLocalizedString("Delete File", comment: "Button title")

        if let cellFolder = cellFolder {
            message = NSLocalizedString("Delete Folder", comment: "")

            if cellFolder.isThirdParty, !(currentFolder?.isThirdParty ?? false) {
                message = NSLocalizedString("Disconnect third party", comment: "")
            }
        }

        alertDelete.addAction(
            UIAlertAction(
                title: message,
                style: .destructive,
                handler: { action in
                    complation(cell, true)
                }
            )
        )

        if UIDevice.pad {
            alertDelete.modalPresentationStyle = .popover
            alertDelete.popoverPresentationController?.sourceView = menuButton
            alertDelete.popoverPresentationController?.sourceRect = menuButton.bounds
            alertDelete.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            flashBlockInteration()
        } else {
            alertDelete.addAction(
                UIAlertAction(
                    title: ASCLocalization.Common.cancel,
                    style: .cancel,
                    handler: { action in
                        complation(cell, false)
                    }
                )
            )
        }

        present(alertDelete, animated: true, completion: nil)
        hideableViewControllerOnTransition = alertDelete
    }
}

// MARK: - Help funcs

extension ASCDocumentsViewController {
    enum NotificationType {
        case `default`, alert
    }

    func getLocalAndCloudItems(indexes: Set<String>) -> (localItems: [ASCEntity], cloudItems: [ASCEntity]) {
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
        return (localItems, cloudItems)
    }

    func getProviderIndexes(items: [ASCEntity]) -> [IndexPath] {
        items.compactMap(indexPath(by:)).map { $0 }
    }
}

private enum CompletionBehavior {
    case delete(UITableViewCell)
    case archiveAction
}
