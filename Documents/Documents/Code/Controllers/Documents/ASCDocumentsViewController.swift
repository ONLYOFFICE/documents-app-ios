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
import ObjectMapper
import SwiftMessages
import SwiftRater
import SwiftUI
import UIKit

typealias MovedEntities = [ASCEntity]
typealias UnmovedEntities = [ASCEntity]

class ASCDocumentsViewController: ASCBaseViewController, UIGestureRecognizerDelegate {
    static let identifier = String(describing: ASCDocumentsViewController.self)

    var itemsViewType: ASCEntityViewLayoutType {
        get {
            return provider?.itemsViewType(for: folder) ?? .list
        }
        set {
            provider?.itemsViewType = newValue
        }
    }

    private var topBannerViewModel: TopBannerViewModel? {
        (provider as? TopBannerViewModelDelegate)?.topBannerViewModel(for: folder)
    }

    private lazy var collectionHeaderView: TopBannerView = {
        let header = TopBannerView(frame: CGRect(x: .zero, y: -TopBannerView.bannerHeight, width: view.frame.width, height: TopBannerView.bannerHeight))
        if let viewModel = topBannerViewModel {
            header.configure(viewModel: viewModel)
        }
        return header
    }()

    // MARK: - Public

    var folder: ASCFolder? {
        didSet {
            folderHolders.forEach { $0.folder = folder }
            if oldValue == nil, let folder {
                displayCategoryTabsIfNeeded(folder: folder)
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

    var total: Int {
        provider?.total ?? 0
    }

    var tableData: [ASCEntity] {
        provider?.items ?? []
    }

    var isEditingIndexMode = false {
        didSet {
            guard isEditingIndexMode != oldValue else { return }
            configureNavigationBar(animated: true)
            updateUIForEditingOrderIndexState()
            collectionView.reloadData()
        }
    }

    var selectedIds: Set<String> = []

    // MARK: - Private

    private lazy var loadedDocumentsViewControllerFinder: ASCLoadedViewControllerFinderProtocol = ASCLoadedDocumentViewControllerByProviderAndFolderFinder()
    private let kPageLoadingCellTag = 7777
    private let swipeToPreviousFolderGestureRecognizerName = "swipeRight"
    private var highlightEntity: ASCEntity?
    private var hideableViewControllerOnTransition: UIViewController?
    private var needsToLoadFirstPageOnAppear = false

    private(set) lazy var navigationBarExtendPanelView: NavigationBarExtendPanelView = {
        let view = NavigationBarExtendPanelView(contentView: contentControl)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var contentControl: ASCCategorySegmentControl = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.onChange = onCategorySegmentChange
        return $0
    }(ASCCategorySegmentControl(frame: .zero))

    private var showTopBanner: Bool {
        return topBannerViewModel != nil
    }

    var categories: [ASCSegmentCategory] = [] {
        didSet {
            updateCategoryTabs()
        }
    }

    var displaySegmentTabs: Bool {
        categories.count > 0
    }

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
        removerActionController: removerActionController
    ) { cell, menuButton, complation in
        // TODO: Refactor me
    }

    // FileProviderHolders getter
    private var fileProviderHolders: [FileProviderHolder] {
        [removerActionController, folderCellContextMenu]
    }

    // FolderHolders getter
    private var folderHolders: [FolderHolder] {
        [removerActionController, folderCellContextMenu]
    }

    // Navigation bar items
    var addBarButton: UIBarButtonItem?
    var sortSelectBarButton: UIBarButtonItem?
    var sortBarButton: UIBarButtonItem?
    var selectBarButton: UIBarButtonItem?
    var cancelBarButton: UIBarButtonItem?
    var selectAllBarButton: UIBarButtonItem?
    var filterBarButton: UIBarButtonItem?
    var reorderIndexButton: UIBarButtonItem?

    lazy var collectionView: ASCDocumentsCollectionView = {
        let collectionView = ASCDocumentsCollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.ascDocumentsDelegate = self

        collectionView.register(ASCFolderViewCell.self, forCellWithReuseIdentifier: ASCFolderViewCell.identifier)
        collectionView.register(ASCFileViewCell.self, forCellWithReuseIdentifier: ASCFileViewCell.identifier)
        collectionView.register(ASCLoaderViewCell.self, forCellWithReuseIdentifier: ASCLoaderViewCell.identifier)

        return collectionView
    }()

    private lazy var applyButton: UIButton = {
        $0.setTitle(NSLocalizedString("Apply", comment: "Button title"), for: .normal)
        $0.backgroundColor = .clear
        $0.setTitleColor(Asset.Colors.brend.color, for: .normal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(onApplyButtonTapped), for: .touchUpInside)
        $0.isHidden = true
        return $0
    }(UIButton())

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
            navigationItem.hidesSearchBarWhenScrolling = true
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
    let events = EventManager()

    // Interaction Controller
    fileprivate lazy var documentInteraction: UIDocumentInteractionController = UIDocumentInteractionController()

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

        view.menuForType[.formFillingRoom] = makePDFFormAction()
        view.menuForType[.formFillingRoomSubfolder] = makePDFFormAction()
        view.onAction = { [weak self] in
            guard
                let self,
                let folder = folder,
                let provider = provider
            else { return }

            createFirstItem(view.actionButton)

            view.actionButton.isHidden = !provider.allowEdit(entity: folder)
        }
        return view
    }()

    private(set) lazy var errorView: ASCDocumentsEmptyView? = {
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

    private(set) lazy var categoryIsRecent: Bool = {
        guard let onlyOfficeProvider = provider as? ASCOnlyofficeProvider else { return false }
        return onlyOfficeProvider.category?.folder?.rootFolderType == .recent
    }()

    private(set) lazy var categoryIsFavorite: Bool = {
        guard let onlyOfficeProvider = provider as? ASCOnlyofficeProvider else { return false }
        return onlyOfficeProvider.category?.folder?.rootFolderType == .favorites
    }()

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        definesPresentationContext = true

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
        addObserver(ASCConstants.Notifications.updateDocumentsViewLayoutType, #selector(updateDocumentsViewLayoutType(_:)))
        addObserver(UIApplication.willResignActiveNotification, #selector(onAppMovedToBackground))
        addObserver(UIApplication.didEnterBackgroundNotification, #selector(onAppDidEnterBackground))

        UserDefaults.standard.addObserver(self, forKeyPath: ASCConstants.SettingsKeys.sortDocuments, options: [.new], context: nil)

        configureNavigationItem()
        configureView()
        viewDidLayoutSubviews()
    }

    private func configureView() {
        view.backgroundColor = .systemBackground

        view.addSubview(collectionView)
        view.addSubview(applyButton)

        if showTopBanner {
            collectionView.addSubview(collectionHeaderView)
            collectionView.contentInset.top = TopBannerView.bannerHeight
        }

        collectionView.anchor(
            top: view.topAnchor,
            leading: view.leadingAnchor,
            bottom: view.safeAreaLayoutGuide.bottomAnchor,
            trailing: view.trailingAnchor
        )

        applyButton.anchor(
            leading: view.leadingAnchor,
            bottom: view.bottomAnchor,
            trailing: view.trailingAnchor,
            padding: UIEdgeInsets(top: .zero, left: .zero, bottom: 50, right: .zero)
        )

        if displaySegmentTabs {
            view.addSubview(navigationBarExtendPanelView)

            navigationBarExtendPanelView.anchor(
                top: view.topAnchor,
                leading: view.leadingAnchor,
                trailing: view.trailingAnchor
            )
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let topInset: CGFloat = showTopBanner ? TopBannerView.bannerHeight : .zero

        if navigationBarExtendPanelView.isHidden || tableData.isEmpty {
            collectionView.contentInset.top = topInset
        } else if displaySegmentTabs {
            collectionView.contentInset.top = (navigationBarExtendPanelView.contentView?.frame.height ?? 0) + topInset
        }

        collectionView.bringSubviewToFront(collectionHeaderView)

        collectionView.verticalScrollIndicatorInsets.top = collectionView.contentInset.top
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

        updateItemsViewType()

        if needsToLoadFirstPageOnAppear {
            needsToLoadFirstPageOnAppear.toggle()
            loadFirstPage()
        }

        if UIDevice.phone, let navigationController = navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationItem.leftBarButtonItem = nil
            }
        }

        showToolBar(collectionView.isEditing)

        ASCViewControllerManager.shared.rootController?.tabBar.isHidden = collectionView.isEditing
        updateLargeTitlesSize()

        if folder?.parent == nil {
            splitViewController?.presentsWithGesture = true
            let gesture = view.gestureRecognizers?.filter { $0.name == swipeToPreviousFolderGestureRecognizerName }
            gesture?.first?.isEnabled = false
        } else {
            splitViewController?.presentsWithGesture = false
        }

        configureNavigationBar()
        viewDidLayoutSubviews()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        if displaySegmentTabs {
            var navigationController = navigationController

            if let splitVC: UISplitViewController = findParentController() {
                navigationController = splitVC.viewControllers.last(where: { $0 is UINavigationController }) as? UINavigationController
            }

            if let navBar = navigationController?.navigationBar,
               let contentView = navigationBarExtendPanelView.contentView,
               navBar.window != nil,
               contentView.window != nil
            {
                if contentView.constraints.first(where: { $0.identifier == "navBarExtendContentViewTop" }) == nil {
                    let constarint = contentView.topAnchor.constraint(equalTo: navBar.bottomAnchor)
                    constarint.identifier = "navBarExtendContentViewTop"
                    constarint.isActive = true
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        collectionView.refreshControl = uiRefreshControl

        checkUnsuccessfullyOpenedFile()
        configureProvider()

        // Update current provider if needed
        if let provider, provider.id != ASCFileManager.provider?.id {
            ASCFileManager.provider = provider
        }

        // Store last open folder
        if let folder, let folderAsString = folder.toJSONString() {
            UserDefaults.standard.set(folderAsString, forKey: ASCConstants.SettingsKeys.lastFolder)
        }

        navigationItem.searchController = tableData.isEmpty ? nil : searchController
        navigationController?.navigationBar.prefersLargeTitles = !tableData.isEmpty && ASCAppSettings.Feature.allowLargeTitle
        navigationItem.largeTitleDisplayMode = !tableData.isEmpty ? .automatic : .never

        updateTitleView(collectionView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupTitleView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        navigationItem.searchController = nil

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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if let viewController = hideableViewControllerOnTransition {
            viewController.dismiss(animated: true, completion: nil)
            hideableViewControllerOnTransition = nil
        }

        delay(seconds: 0.1) { [weak self] in
            guard let self else { return }
            self.viewIsAppearing(true)
            self.collectionView.updateLayout()
        }

        collectionView.reloadSections(IndexSet(integer: 0))
    }

    private func cleanup() {
        if provider == nil {
            return
        }

        provider = nil
        UserDefaults.standard.removeObserver(self, forKeyPath: ASCConstants.SettingsKeys.sortDocuments)
        NotificationCenter.default.removeObserver(self)
    }

    private func displayCategoryTabsIfNeeded(folder: ASCFolder) {
        categories = provider?.segmentCategory(of: folder) ?? []
    }

    private func updateCategoryTabs() {
        contentControl.items = categories
        contentControl.selectIndex = categories.count > 0 ? 0 : nil
    }

    private func onCategorySegmentChange(_ category: ASCSegmentCategory) {
        folder = category.folder

        if let onlyofficeProvider = provider as? ASCOnlyofficeProvider {
            onlyofficeProvider.folder = folder
        }

        provider?.cancel()
        provider?.reset()

        UIView.performWithoutAnimation { [weak self] in
            self?.collectionView.reloadData()
        }

        loadFirstPage()
    }

    private func updateItemsViewType() {
        collectionView.layoutType = itemsViewType

        let visibleCells = collectionView.visibleCells as? [ASCEntityViewCellProtocol] ?? [ASCEntityViewCellProtocol]()
        for cell in visibleCells {
            cell.layoutType = itemsViewType
        }

        collectionView.reloadSections(IndexSet(integer: 0))
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

        UIView.performWithoutAnimation { [weak self] in
            self?.collectionView.reloadData()
        }
    }

    @objc func refresh(_ refreshControl: UIRefreshControl) {
        if searchController.isActive {
            refreshControl.endRefreshing()
            return
        }

        provider?.page = 0

        fetchData { [weak self] success in
            DispatchQueue.main.async { [weak self] in
                refreshControl.endRefreshing()

                guard let self else { return }

                self.showErrorView(!success)

                if success {
                    self.showEmptyView(self.total < 1)
                }

                self.updateNavBar()
            }
        }
    }

    func add(entity: Any, open: Bool = true) {
        guard let provider else { return }

        if let file = entity as? ASCFile {
            file.parent = file.parent ?? folder

            provider.add(item: file, at: 0)

            provider.updateSort { provider, currentFolder, success, error in
                UIView.performWithoutAnimation { [weak self] in
                    self?.collectionView.reloadData()
                }
                self.showEmptyView(self.total < 1)

                if let index = self.tableData.firstIndex(where: { $0.id == file.id }) {
                    self.navigationItem.searchController = self.searchController
                    self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredVertically, animated: true)
                    self.collectionView.setNeedsLayout()

                    delay(seconds: 0.3) { [weak self] in
                        if let newCell = self?.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) {
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
                let isForm = ([ASCConstants.FileExtensions.pdf] + ASCConstants.FileExtensions.forms).contains(fileExt)

                if isDocument || isSpreadsheet || isPresentation || isForm {
                    provider.open(file: file, openMode: .create, canEdit: true)
                }
            }
        } else if let folder = entity as? ASCFolder {
            provider.add(item: folder, at: 0)

            provider.updateSort { provider, currentFolder, success, error in
                UIView.performWithoutAnimation { [weak self] in
                    self?.collectionView.reloadData()
                }

                self.showEmptyView(self.total < 1)

                if let index = self.tableData.firstIndex(where: { $0.uid == folder.uid }) {
                    self.navigationItem.searchController = self.searchController
                    self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredVertically, animated: true)
                    self.collectionView.setNeedsLayout()

                    delay(seconds: 0.3) { [weak self] in
                        if let newCell = self?.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) {
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
                    collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredVertically, animated: false)

                    if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) {
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

    func updateSelectedItems(indexPath: IndexPath) {
        if let folder = tableData[indexPath.row] as? ASCFolder {
            selectedIds.insert(folder.uid)
        } else if let file = tableData[indexPath.row] as? ASCFile {
            selectedIds.insert(file.uid)
        }
        events.trigger(eventName: "item:didSelect")
        configureToolBar()
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
            collectionView.refreshControl = nil
        }
    }

    private func configureToolBar() {
        guard let folder = folder else {
            return
        }

        let isRoot = folder.parentId == nil || folder.parentId == "0"
        let isRoomList = folder.isRoomListFolder
        let isDevice = (provider?.id == ASCFileManager.localProvider.id)
        let isShared = folder.rootFolderType == .share
        let isTrash = self.isTrash(folder)
        let isRecent = categoryIsRecent
        let isProjectRoot = (folder.rootFolderType == .bunch || folder.rootFolderType == .projects) && isRoot
        let isGuest = ASCFileManager.onlyofficeProvider?.user?.isVisitor ?? false
        let isPersonalCategory = folder.rootFolderType == .user
        let isDocSpace = (provider as? ASCOnlyofficeProvider)?.apiClient.serverVersion?.docSpace != nil
        let isDocSpaceArchive = isRoomList && folder.rootFolderType == .archive
        let isDocSpaceArchiveRoomContent = folder.rootFolderType == .archive && !isRoot
        let isDocSpaceRoomShared = isRoomList && folder.rootFolderType == .virtualRooms
        let isInfoShowing = (isDocSpaceRoomShared || isDocSpaceArchive) && selectedIds.count <= 1
        let isNeededUpdateToolBarOnSelection = isDocSpaceRoomShared || folder.isRoomListSubfolder
        let isNeededUpdateToolBarOnDeselection = isDocSpaceRoomShared || folder.isRoomListSubfolder || isDocSpaceArchive

        events.removeListeners(eventNameToRemoveOrNil: "item:didSelect")
        events.removeListeners(eventNameToRemoveOrNil: "item:didDeselect")

        let fixedWidthButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let barIconSpacer = UIBarButtonItem(customView: fixedWidthButton)
        let barFlexSpacer: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let createBarButton: (_ image: UIImage, _ selector: Selector) -> UIBarButtonItem = { [weak self] image, selector in
            guard let strongSelf = self else { return UIBarButtonItem() }
            let buttonItem = ASCStyles.createBarButton(image: image, target: strongSelf, action: selector)

            buttonItem.isEnabled = (strongSelf.collectionView.indexPathsForSelectedItems?.count ?? 0) > 0

            strongSelf.events.listenTo(eventName: "item:didSelect") { [weak self] in
                buttonItem.isEnabled = (self?.collectionView.indexPathsForSelectedItems?.count ?? 0) > 0
            }
            strongSelf.events.listenTo(eventName: "item:didDeselect") { [weak self] in
                buttonItem.isEnabled = (self?.collectionView.indexPathsForSelectedItems?.count ?? 0) > 0
            }

            return buttonItem
        }

        var items: [UIBarButtonItem] = []

        // Create room
        if isPersonalCategory, isDocSpace {
            items.append(createBarButton(Asset.Images.barRectanglesAdd.image, #selector(onTransformToRoomSelected)))
            items.append(barFlexSpacer)
        }

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
        if isDevice || !(isShared || isProjectRoot || isGuest || isRecent || isDocSpaceRoomShared || isDocSpaceArchiveRoomContent || isDocSpaceArchive) {
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
        if isDocSpaceArchive, !isInfoShowing {
            items.append(barIconSpacer)
            items.append(barFlexSpacer)
        } else if isInfoShowing {
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
        if isDocSpaceRoomShared, canArchiveAllSelectedItems() {
            items.append(createBarButton(Asset.Images.barArchive.image, #selector(onArchiveSelected)))
            items.append(barFlexSpacer)
        }

        // Restore room
        if isDocSpaceArchive {
            items.append(createBarButton(Asset.Images.barTrashSlash.image, #selector(onRoomRestore)))
            items.append(barFlexSpacer)
        }

        // Remove all
        if isTrash {
            items.append(UIBarButtonItem(image: Asset.Images.barDeleteAll.image, style: .plain, target: self, action: #selector(onEmptyTrashSelected)))
            items.append(barFlexSpacer)
        }

        // Remove all rooms
        if isDocSpaceArchive, canRemoveAllItems() {
            let deleteButton = UIBarButtonItem(
                image: Asset.Images.barDelete.image,
                style: .plain,
                target: self,
                action: #selector(onRemoveArchivedRooms)
            )
            deleteButton.tintColor = .red

            items.append(deleteButton)
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

    private func updateUIForEditingOrderIndexState() {
        if isEditingIndexMode {
            ASCViewControllerManager.shared.rootController?.tabBar.isHidden = true
            applyButton.isHidden = false
        } else {
            ASCViewControllerManager.shared.rootController?.tabBar.isHidden = false
            applyButton.isHidden = true
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

    private func showToolBar(_ show: Bool, animated: Bool = true) {
        navigationController?.setToolbarHidden(!show, animated: animated)
        ASCViewControllerManager.shared.rootController?.tabBar.isHidden = show
    }

    func setEditMode(_ edit: Bool) {
        collectionView.isEditing = edit
        isEditingIndexMode = false
        selectedIds.removeAll()

        configureNavigationBar()

        configureToolBar()
        showToolBar(edit)

        updateTitle()
    }

    private func fetchData(_ completeon: ((Bool) -> Void)? = nil) {
        guard let provider else {
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
            guard let self else { return }
            UIView.performWithoutAnimation { [weak self] in
                self?.collectionView.reloadData()
            }
            self.showEmptyView(self.total < 1)

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

            let sortInfo: [String: Any]? = {
                guard let sortInfoOnRootFolderType = UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any] else {
                    return nil
                }
                return sortInfoOnRootFolderType[String(folder.rootFolderType.rawValue)] as? [String: Any]
                    ?? UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any]
            }()

            if let sortInfo {
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
                    let self,
                    let folder = entity as? ASCFolder
                else { return }

                let isCanceled: Bool = {
                    guard let error = error as? NetworkingError, case NetworkingError.cancelled = error else {
                        return false
                    }
                    return true
                }()

                if !isCanceled {
                    self.showErrorView(!success, error)
                }

                if success || isCanceled {
                    self.folder = folder
                    UIView.performWithoutAnimation { [weak self] in
                        self?.collectionView.reloadData()
                    }

                    self.showEmptyView(self.total < 1)
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

    func loadFirstPage(_ completeon: ((_ success: Bool) -> Void)? = nil) {
//        provider?.page = 0

        if needsToLoadFirstPageOnAppear {
            provider?.cancel()
            provider?.reset()
            UIView.performWithoutAnimation { [weak self] in
                self?.collectionView.reloadData()
            }
        }

        setEditMode(false)
        showLoadingPage(true)

        if searchController.isActive {
            searchController.isActive = false
        }

        navigationItem.searchController = nil

        addBarButton?.isEnabled = false // Disable create entity while loading first page

        fetchData { [weak self] success in
            DispatchQueue.main.async {
                guard let self else { return }

                // UI update
                self.showLoadingPage(false)

                if success {
                    self.showEmptyView(self.total < 1)
                } else {
                    if self.errorView?.superview == nil {
                        self.showErrorView(true)
                    }
                }

                self.updateNavBar()

                // Fire callback
                completeon?(success)

                self.navigationItem.searchController = self.tableData.isEmpty ? nil : self.searchController
                self.viewDidLayoutSubviews()

                // Highlight entity if needed
                self.highlight(entity: self.highlightEntity)

                // Check network
                if !success,
                   self.folder?.rootFolderType != .deviceDocuments,
                   !ASCNetworkReachability.shared.isReachable,
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
            loadingView.anchorCenterXToSuperview()
            loadingView.anchorCenterYToSuperview(constant: 40)

        } else {
            loadingView.removeFromSuperview()
        }
    }

    func showEmptyView(_ show: Bool) {
        if !searchController.isActive {
            navigationItem.searchController = show ? nil : searchController
        }

        if !show {
            emptyView?.removeFromSuperview()
            searchEmptyView?.removeFromSuperview()

            emptyView?.isHidden = true
            searchEmptyView?.isHidden = true

            navigationController?.navigationBar.prefersLargeTitles = ASCAppSettings.Feature.allowLargeTitle
            navigationItem.largeTitleDisplayMode = .automatic

        } else {
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never

            let localEmptyView = searchController.isActive ? searchEmptyView : emptyView
            let isDocSpace = (provider as? ASCOnlyofficeProvider)?.apiClient.serverVersion?.docSpace != nil
            let isDocRecently = isDocSpace && folder?.rootFolderType == .recent

            // If loading view still display
            if let _ = loadingView.superview {
                return
            }

            localEmptyView?.isHidden = false

            if searchController.isActive {
                localEmptyView?.type = .search
            } else {
                if let folder, let provider {
                    let hasPermission = provider.allowEdit(entity: folder)
                    if folder.rootFolderType == .deviceTrash || folder.rootFolderType == .trash {
                        localEmptyView?.type = .trash
                    } else if folder.rootFolderType == .roomTemplates {
                        localEmptyView?.type = .roomTemplates
                    } else if folder.rootFolderType == .archive, !folder.isRoom {
                        localEmptyView?.type = .docspaceArchive
                    } else if provider.type == .local {
                        localEmptyView?.type = .local
                    } else if let provider = provider as? ASCOnlyofficeProvider,
                              !folder.isRoom,
                              folder.isRoomListSubfolder,
                              let folder = provider.folder,
                              folder.parentsFoldersOrCurrentContains(keyPath: \.roomType, value: .fillingForm),
                              provider.allowEdit(entity: folder)
                    {
                        localEmptyView?.type = .formFillingRoomSubfolder
                    } else if folder.isRoom {
                        if folder.roomType == .fillingForm {
                            localEmptyView?.type = hasPermission ? .formFillingRoom : .formFillingNoPermissions
                        } else if folder.roomType == .virtualData {
                            localEmptyView?.type = hasPermission ? .virtualDataRoom : .virtualDataRoomNoPermissions
                        } else if folder.roomType == .public {
                            localEmptyView?.type = hasPermission ? .publicRoom : .publicRoomNoPermissions
                        } else if folder.roomType == .colobaration {
                            localEmptyView?.type = hasPermission ? .collaborationRoom : .collaborationRoomNoPermissions
                        } else if folder.roomType == .custom {
                            localEmptyView?.type = hasPermission ? .customRoom : .customRoomNoPermissions
                        } else if !(provider.allowEdit(entity: folder)) {
                            localEmptyView?.type = .docspaceNoPermissions
                        }
                    } else if isDocRecently {
                        localEmptyView?.type = .recentlyAccessibleViaLink
                    } else {
                        localEmptyView?.type = .cloud
                        if !(provider.allowEdit(entity: folder)) {
                            if folder.rootFolderType == .virtualRooms  {
                                localEmptyView?.type = .docspaceEmptyRooms
                            } else {
                                localEmptyView?.type = .cloudNoPermissions
                            }
                        }
                    }
                }
            }

            guard
                let localEmptyView, localEmptyView.superview == nil
            else { return }

            view.insertSubview(localEmptyView, aboveSubview: collectionView)
            localEmptyView.fillToSuperview()
        }
    }

    private func showErrorView(_ show: Bool, _ error: Error? = nil) {
        if !show {
            errorView?.removeFromSuperview()
        } else if tableData.count < 1 {
            showLoadingPage(false)
            showEmptyView(false)

            errorView?.type = .error
            errorView?.subtitleLabel?.text = "\(errorView?.subtitleLabel?.text ?? "")"

            if let error = error as? NetworkingError {
                switch error {
                case let .apiError(error):
                    if let onlyofficeError = error as? OnlyofficeServerError {
                        switch onlyofficeError {
                        case .paymentRequired:
                            errorView?.type = .paymentRequired
                            errorView?.onAction = {
                                if let url = URL(string: OnlyofficeApiClient.shared.baseURL?.absoluteString ?? ASCConstants.Urls.applicationPage) {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            }
                        default:
                            errorView?.type = .error
                            errorView?.subtitleLabel?.text = "\(errorView?.subtitleLabel?.text ?? "") (\(error.localizedDescription))"
                        }
                    }
                case .noInternet:
                    errorView?.type = .networkError
                case .cancelled, .sessionDeinitialized:
                    return
                default:
                    errorView?.type = .error
                    errorView?.subtitleLabel?.text = "\(errorView?.subtitleLabel?.text ?? "") (\(error.localizedDescription))"
                }
            }

            guard
                let errorView, errorView.superview == nil
            else { return }

            view.insertSubview(errorView, aboveSubview: collectionView)
            errorView.fillToSuperview()
        }
    }

    private func makePDFFormAction() -> UIMenu {
        let menu = UIMenu(title: "", children: [
            UIAction(title: NSLocalizedString("From DocSpace", comment: ""), image: Asset.Images.createExport.image) { [weak self] action in
                guard let self else { return }
                let createEntity = ASCCreateEntity(provider: provider)
                createEntity.uploadPDFFromDocspace(viewController: self)
            },
            UIAction(title: NSLocalizedString("From device", comment: ""), image: Asset.Images.createExport.image) { [weak self] action in
                guard let self else { return }
                let createEntity = ASCCreateEntity(provider: provider)
                createEntity.uploadPDFFromDevice(viewController: self)
            },
        ])

        return menu
    }

    @objc func updateFileInfo(_ notification: Notification) {
        if let file = notification.object as? ASCFile {
            if let path = indexPath(by: file) {
                if let index = provider?.items.firstIndex(where: { ($0 as? ASCFile)?.id == file.id }) {
                    provider?.items[index] = file
                }

                collectionView.reloadSections(IndexSet(integer: 0))

                delay(seconds: 0.3) { [weak self] in
                    if let cell = self?.collectionView.cellForItem(at: path) {
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
        UIView.performWithoutAnimation { [weak self] in
            self?.collectionView.reloadData()
        }
    }

    @objc
    private func updateDocumentsViewLayoutType(_ notification: Notification) {
        updateItemsViewType()
        configureNavigationBar()
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

    func currentFolderActionMenu(for button: UIButton) -> UIMenu? {
        guard let folder else { return nil }
        return CurrentFolderMenu().contextMenu(for: folder, in: self)
    }

    func highlight(cell: UICollectionViewCell) {
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
            highlightView.backgroundColor = .tertiarySystemGroupedBackground
        }) { finished in
            UIView.animate(withDuration: 0.5, animations: {
                highlightView.backgroundColor = originalBgColor
            }) { finished in
                highlightView.removeFromSuperview()
            }
        }
    }

    func indexPath(by entity: ASCEntity) -> IndexPath? {
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

    func isTrash(_ folder: ASCFolder?) -> Bool {
        provider?.isTrash(for: folder) ?? false
    }

    private func configureSwipeGesture() {
        let swipeToPreviousFolder = UISwipeGestureRecognizer(target: self, action: #selector(popViewController))
        swipeToPreviousFolder.direction = .right
        swipeToPreviousFolder.name = swipeToPreviousFolderGestureRecognizerName
        view.addGestureRecognizer(swipeToPreviousFolder)
    }

    // MARK: - Open files

    func open(file: ASCFile, openMode: ASCDocumentOpenMode = .edit) {
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
            provider?.open(file: file, openMode: openMode, canEdit: provider?.allowEdit(entity: file) ?? false)
            searchController.isActive = false
        } else {
            var cell: UICollectionViewCell? = nil
            if let index = tableData.firstIndex(where: { $0.id == file.id }) {
                cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0))
            }
            provider?.delegate = self
            provider?.preview(file: file, openMode: openMode, files: (tableData.filter { $0 is ASCFile }) as? [ASCFile], in: cell)
        }

        // Reset as New
        if let fileIndex = tableData.firstIndex(where: { $0.id == file.id }) {
            (tableData[fileIndex] as? ASCFile)?.isNew = false
            collectionView.reloadItems(at: [IndexPath(row: fileIndex, section: 0)])
        }
    }

    func checkUnsuccessfullyOpenedFile() {
        ASCEditorManager.shared.checkUnsuccessfullyOpenedFile(parent: self)
    }

    // MARK: - Entity actions

    func openFolder(folder: ASCFolder) {
        let transitionToFolderCompletion: (ASCFolder?) -> Void = { [weak navigationController, provider] folder in
            guard let folder else { return }
            let controller = ASCDocumentsViewController.instantiate(from: Storyboard.main)
            navigationController?.pushViewController(controller, animated: true)

            controller.provider = provider?.copy()
            controller.provider?.cancel()
            controller.provider?.reset()
            controller.folder = folder
            controller.title = folder.title
        }

        guard folder.passwordProtected else {
            transitionToFolderCompletion(folder)
            return
        }

        showPasswordAlert { [provider] password in
            guard let password, !password.isEmpty else { return }
            provider?.getAccess(for: folder, password: password, completion: { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(folder):
                    transitionToFolderCompletion(folder)
                case let .failure(error):
                    UIAlertController.showError(in: self, message: error.localizedDescription)
                }
            })
        }
    }

    func showPasswordAlert(onCompletion: @escaping (String?) -> Void) {
        var alert: UIAlertController?
        alert = UIAlertController.alert(
            NSLocalizedString("Enter password", comment: ""),
            message: NSLocalizedString("You need a password to access the room", comment: ""),
            actions: [
                UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil),
                UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: { _ in
                    let password = alert?.textFields?.first?.text
                    onCompletion(password)
                }),
            ]
        )

        alert?.addTextField { textField in
            textField.placeholder = "Enter password"
            textField.isSecureTextEntry = true
        }

        if let alert = alert {
            present(alert, animated: true)
        }
    }

    func delete(cell: UICollectionViewCell) {
        guard let entity = (cell as? ASCEntityViewCellProtocol)?.entity else { return }

        if let file = entity as? ASCFile {
            handleFileDeletion(file)
        } else if let folder = entity as? ASCFolder {
            handleFolderDeletion(folder)
        }
    }

    private func handleFileDeletion(_ file: ASCFile) {
        switch folder?.rootFolderType {
        case .trash:
            showDeleteFromOnlyofficeTrash(entity: file)
        case .deviceTrash:
            showDeleteFromDeviceTrash(entity: file)
        default:
            removerActionController.delete(indexes: [file.uid])
        }
    }

    private func handleFolderDeletion(_ folder: ASCFolder) {
        switch self.folder?.rootFolderType {
        case .archive:
            deleteArchive(folder: folder)
        case .trash:
            showDeleteFromOnlyofficeTrash(entity: folder)
        case .deviceTrash:
            showDeleteFromDeviceTrash(entity: folder)
        default:
            removerActionController.delete(indexes: [folder.uid])
        }
    }

    func showDeleteAlert(title: String, message: String, deleteHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { _ in
            deleteHandler()
        }

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    func showDeleteFromOnlyofficeTrash(entity: ASCEntity) {
        if let file = entity as? ASCFile {
            showDeleteAlert(
                title: NSLocalizedString("Delete forever?", comment: ""),
                message: AlertMessageType.deleteFileFromTrash.message
            ) {
                self.removerActionController.delete(indexes: [file.uid])
            }
        } else if let folder = entity as? ASCFolder {
            showDeleteAlert(
                title: NSLocalizedString("Delete forever?", comment: ""),
                message: AlertMessageType.deleteFolderFromTrash.message
            ) {
                self.removerActionController.delete(indexes: [folder.uid])
            }
        }
    }

    func showDeleteFromDeviceTrash(entity: ASCEntity) {
        showDeleteAlert(
            title: NSLocalizedString("Delete this item?", comment: ""),
            message: AlertMessageType.deleteFromDeviceTrash.message
        ) {
            self.removerActionController.delete(indexes: [entity.uid])
        }
    }

    func deleteArchive(folder: ASCFolder) {
        showDeleteAlert(
            title: NSLocalizedString("Delete forever?", comment: ""),
            message: AlertMessageType.deleteRoomFromArchive.message
        ) {
            self.removerActionController.delete(indexes: [folder.uid])
        }
    }

    func deleteRoomTempateAlert(template: ASCFolder, handler: @escaping () -> Void) {
        showDeleteAlert(
            title: NSLocalizedString("Delete template", comment: ""),
            message: AlertMessageType.deleteRoomTemplate(template.title).message
        ) {
            handler()
        }
    }

    func showRestoreRoomAlert(handler: @escaping () -> Void) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Restore room?", comment: ""),
            message: AlertMessageType.restoreRoomFromArchive.message,
            preferredStyle: .alert
        )

        let restoreAction = UIAlertAction(
            title: NSLocalizedString("Restore", comment: ""),
            style: .default
        ) { _ in
            handler()
        }

        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel, handler: nil)

        alertController.addAction(restoreAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    func restoreRoom() {
        guard selectedIds.count > 0 else { return }
        tableData.filter { selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFolder }
            .forEach {
                guard
                    let indexPath = indexPath(by: $0),
                    let cell = collectionView.cellForItem(at: indexPath)
                else { return }
                unarchive(cell: cell, folder: $0)
            }
        showEmptyView(total < 1)
        updateNavBar()
        setEditMode(false)
    }

    func rename(cell: UICollectionViewCell) {
        guard
            let provider,
            let entity = (cell as? ASCEntityViewCellProtocol)?.entity
        else { return }

        var hud: MBProgressHUD?

        ASCEntityManager.shared.rename(for: provider, entity: entity) { [unowned self] status, entity, error in
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
                if let entity {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: .standardDelay)

                    if let indexPath = self.collectionView.indexPath(for: cell),
                       let entity = entity as? ASCEntity
                    {
                        self.provider?.items[indexPath.row] = entity
                        self.collectionView.reloadItems(at: [indexPath])

                        if let updatedCell = self.collectionView.cellForItem(at: indexPath) {
                            self.highlight(cell: updatedCell)
                        }
                    }
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }

    func archive(cell: UICollectionViewCell?, folder: ASCFolder) {
        let processLabel: String = NSLocalizedString("Archiving", comment: "Caption of the processing")
        if let cell {
            handleAction(folder: folder, action: .archive, processingLabel: processLabel, copmletionBehavior: .delete(cell))
        } else {
            handleAction(folder: folder, action: .archive, processingLabel: processLabel, copmletionBehavior: .archiveAction)
        }
    }

    func unarchive(cell: UICollectionViewCell?, folder: ASCFolder) {
        let processLabel: String = NSLocalizedString("Moving from archive", comment: "Caption of the processing")
        if let cell {
            handleAction(folder: folder, action: .unarchive, processingLabel: processLabel, copmletionBehavior: .delete(cell))
        } else {
            handleAction(folder: folder, action: .unarchive, processingLabel: processLabel, copmletionBehavior: .archiveAction)
        }
    }

    func disableNotifications(room: ASCFolder) {
        RoomSharingNetworkService().toggleRoomNotifications(room: room) { result in
            switch result {
            case let .success(responce):
                if let roomId = Int(room.id),
                   responce.disabledRooms.contains(roomId)
                {
                    room.mute = true
                } else {
                    room.mute = false
                }
            case let .failure(error):
                log.error(error)

                UIAlertController.showError(
                    in: self,
                    message: NSLocalizedString("Something wrong", comment: "")
                )
            }
        }
    }

    func saveAsTemplate(room: ASCFolder) {
        let vc = ASCSaveAsTemplateRootViewController(room: room) { folder in
            DispatchQueue.main.async {
                UIApplication.topViewController()?.dismiss(animated: true)
                MBProgressHUD.currentHUD?.removeFromSuperview()
            }
        }

        if UIDevice.pad {
            vc.isModalInPresentation = true
            vc.modalPresentationStyle = .formSheet
        }
        present(vc, animated: true)
    }

    func editTemplate(template: ASCFolder) {
        let previusIndexingValue = template.indexing

        let vc = ASCEditTemplateRootViewController(template: template) { [weak self] template in
            guard let self else { return }
            self.folder = template
        }

        if let refreshControl = collectionView.refreshControl {
            refresh(refreshControl)
            if let viewControllers = navigationController?.viewControllers,
               let index = viewControllers.firstIndex(of: self),
               index > 0
            {
                let previousController = viewControllers[index - 1] as? ASCDocumentsViewController
                previousController?.refresh(refreshControl)
            }
        }

        // If indexing changed rerender layout with correct type for edited room
        if previusIndexingValue != template.indexing {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: ASCConstants.Notifications.updateDocumentsViewLayoutType,
                    object: self.provider?.itemsViewType(for: template) ?? .list
                )
            }
        }

        vc.modalPresentationStyle = .formSheet
        vc.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize

        present(vc, animated: true, completion: nil)
    }

    func deleteRoomTemplate(template: ASCFolder) {
        Task {
            var hud: MBProgressHUD?

            for await event in ASCRoomTemplatesNetworkService().deleteRoomTemplate(template: template) {
                switch event {
                case .begin:
                    await MainActor.run {
                        hud = MBProgressHUD.showTopMost()
                        hud?.mode = .annularDeterminate
                        hud?.progress = 0
                        hud?.label.text = NSLocalizedString("Deleting", comment: "")
                    }

                case let .progress(value):
                    await MainActor.run {
                        hud?.progress = Float(value)
                    }

                case let .failure(error):
                    await MainActor.run {
                        hud?.hide(animated: true)
                        UIAlertController.showError(
                            in: self,
                            message: error.localizedDescription
                        )
                    }

                case .success:
                    await MainActor.run {
                        hud?.setSuccessState()
                        hud?.hide(animated: false, afterDelay: .standardDelay)
                        loadFirstPage()
                    }
                }
            }
        }
    }

    func createRoomFrom(template: ASCFolder) {
        let vc = ASCCreateRoomFromTemplateRootViewController(template: template) { [weak self] room in
            self?.add(entity: room, open: true)
        }

        if UIDevice.pad {
            vc.isModalInPresentation = true
            vc.modalPresentationStyle = .formSheet
        }
        present(vc, animated: true)
    }

    func duplicateRoom(room: ASCFolder) {
        var hud: MBProgressHUD?

        RoomSharingNetworkService().duplicateRoom(room: room) { [unowned self] status, progress, result, error, cancel in
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
                    message: error?.localizedDescription ?? NSLocalizedString("Could not duplicate the room.", comment: "")
                )
            } else if status == .end {
                hud?.setSuccessState()
                hud?.hide(animated: false, afterDelay: .standardDelay)
                loadFirstPage()
            }
        }
    }

    func showShereFolderAlert(folder: ASCFolder) {
        let alert = UIAlertController(
            title: NSLocalizedString("Share folder", comment: ""),
            message: NSLocalizedString("A new room will be created and all the contents of the selected folder will be copied there. Afterwards, you can invite other users to collaborate on the files within a room.", comment: ""),
            preferredStyle: .alert,
            tintColor: nil
        )

        alert.addCancel()

        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Create", comment: ""),
                style: .default,
                handler: { [unowned self] _ in
                    self.transformToRoom(entities: [folder])
                }
            )
        )

        present(alert, animated: true, completion: nil)
    }

    func fillForm(file: ASCFile) {
        if file.device {
            open(file: file, openMode: .fillform)
            return
        }

        guard file.isForm || file.formFillingStatus == .complete else { return }

        // Workaround a problem https://bugzilla.onlyoffice.com/show_bug.cgi?id=75525
        if let folderOfFile = file.parent, folderOfFile.type == .formFillingFolderDone {
            open(file: file, openMode: .view)
            return
        }

        let isInsideVDRRoom = file.parent?.parentsFoldersOrCurrentContains(
            keyPath: \.roomType,
            value: .virtualData
        ) == true
        if isInsideVDRRoom {
            if file.formFillingStatus == .draft {
                startFilling(file: file)
            } else if file.security.fillForms, file.formFillingStatus == .yourTurn {
                openFormInFillingModeWithCheckingVersion(file: file)
            } else if file.security.startFilling {
                startFilling(file: file)
            } else {
                open(file: file, openMode: .view)
            }
            return
        }

        let isInsideFillingFormRoom = file.parent?.parentsFoldersOrCurrentContains(
            keyPath: \.roomType,
            value: .fillingForm
        ) == true
        if isInsideFillingFormRoom, file.security.fillForms {
            open(file: file, openMode: .fillform)
            return
        }

        let fillFormMenuScreen = FillFormMenuScreenRepresentable(
            onOpenTapped: { [weak self] in
                self?.open(file: file, openMode: .fillform)
            },
            onShareTapped: { [weak self] in
                guard let self else { return }
                let vc = ASCTransferViewController.instantiate(from: Storyboard.transfer)

                let presenter = ASCTransferPresenter(
                    view: vc,
                    provider: provider?.copy(),
                    transferType: .selectFillFormRoom,
                    enableFillRootFolders: true,
                    enableDisplayNewFolderBarButton: false,
                    enableDisplayCreateFillFormRoomBarButton: true,
                    folder: ASCFolder.onlyofficeRoomSharedFolder
                )
                vc.presenter = presenter

                let nc = ASCTransferNavigationController(rootASCViewController: vc)
                let items = [file]
                nc.doneHandler = { [weak self] provider, folder, _ in
                    guard let self, let folder else { return }
                    self.insideCheckTransfer(items: items, to: folder, move: false) { conflictResolveType, cancel in
                        guard !cancel else {
                            return
                        }

                        self.insideTransfer(
                            items: items,
                            to: folder,
                            move: false,
                            conflictResolveType: conflictResolveType
                        ) { movedEntities in
                            guard movedEntities != nil else { return }

                            if let destVC = self.getLoadedViewController(
                                byFolderId: folder.id,
                                andProviderId: provider?.id
                            ) {
                                destVC.loadFirstPage()
                            }
                        }
                    }
                }
                nc.displayActionButtonOnRootVC = true
                nc.modalPresentationStyle = .formSheet
                nc.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
                present(nc, animated: true)
            }
        )

        let hostingController = UIHostingController(rootView: fillFormMenuScreen)
        present(hostingController, animated: true, completion: nil)
    }

    func startFilling(file: ASCFile) {
        guard file.isForm, !file.device else { return }

        open(file: file, openMode: .startFilling)
    }

    func fillingStatus(file: ASCFile) {
        guard file.isForm || file.formFillingStatus == .complete, !file.device else { return }

        let vc = VDRFillingStatusUIHostingController(
            file: file,
            onStoppedSuccess: { [weak self] in
                self?.fetchData()
            },
            onFillTapped: { [weak self] in
                self?.openFormInFillingModeWithCheckingVersion(file: file)
            }
        )
        present(vc, animated: true, completion: nil)
    }

    func openFormInFillingModeWithCheckingVersion(file: ASCFile) {
        guard file.isForm, !file.device else { return }
        if ASCEditorManager.shared.checkSDKVersion() {
            open(file: file, openMode: .fillform)
        } else {
            let alertController = UIAlertController(
                title: NSLocalizedString("Filling form", comment: ""),
                message: NSLocalizedString("The client and server versions are incompatible. You can only open the document in view mode", comment: ""),
                preferredStyle: .alert,
                tintColor: nil
            )

            alertController.addCancel()
            alertController.addOk { [unowned self] _ in
                open(file: file, openMode: .view)
            }
            present(alertController, animated: true, completion: nil)
        }
    }

    func transformToRoom(entities: [ASCEntity]) {
        let entitiesIsOnlyOneFolder: Bool = {
            guard entities.count == 1 else { return false }
            return entities[0] is ASCFolder
        }()
        let suggestedName: String = {
            guard entitiesIsOnlyOneFolder else { return "" }
            return (entities[0] as? ASCFolder)?.title ?? ""
        }()
        let vc = CreateRoomRouteViewViewController(
            roomName: suggestedName,
            hideActivityOnSuccess: false
        ) { [weak self] room in
            let hud: MBProgressHUD? = MBProgressHUD.currentHUD
            self?.provider?.transfer(
                items: entities,
                to: room,
                move: false,
                conflictResolveType: .duplicate,
                contentOnly: entitiesIsOnlyOneFolder
            ) { [weak self] status, progress, result, error, cancel in
                guard let self else { return }
                if status == .error {
                    hud?.hide(animated: false)
                    UIAlertController.showError(
                        in: self,
                        message: error?.localizedDescription ?? NSLocalizedString("Could not copy.", comment: "")
                    )
                } else if status == .end {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: .standardDelay)
                    if let rootVC = ASCViewControllerManager.shared.rootController {
                        rootVC.display(provider: provider, folder: room, inCategory: .virtualRooms)
                    }
                }
            }
        }

        if UIDevice.pad {
            vc.isModalInPresentation = true
            vc.modalPresentationStyle = .formSheet
        }
        present(vc, animated: true, completion: nil)
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
                    hud?.hide(animated: false, afterDelay: .standardDelay)
                    switch copmletionBehavior {
                    case let .delete(cell):
                        if let indexPath = self.collectionView.indexPath(for: cell), entity as? ASCFolder != nil {
                            self.provider?.remove(at: indexPath.row)
                            self.collectionView.deleteItems(at: [indexPath])
                        }

                    case .archiveAction:
                        if let previousController = self.navigationController?.viewControllers[1] as? ASCDocumentsViewController,
                           let folderItem = previousController.collectionView.visibleCells.compactMap({ $0 as? ASCFolderViewCell }).first(where: { ($0.entity as? ASCFolder)?.title == folder.title }),
                           let indexPath = previousController.collectionView.indexPath(for: folderItem)
                        {
                            previousController.provider?.remove(at: indexPath.row)
                            previousController.collectionView.deleteItems(at: [indexPath])

                            if let refreshControl = previousController.collectionView.refreshControl {
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

    func pinToggle(cell: UICollectionViewCell) {
        guard let folder = (cell as? ASCEntityViewCellProtocol)?.entity as? ASCFolder,
              let provider
        else { return }

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
                    hud?.hide(animated: false, afterDelay: .standardDelay)
                    self.loadFirstPage()
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }

    func exportRoomIndex() {
        guard let folder = folder, let provider else { return }
        let hud = MBProgressHUD.showTopMost()
        hud?.isHidden = false
        provider.handle(action: .exportRoomIndex, folder: folder) { [weak self] status, message, error in
            guard let self = self else {
                hud?.hide(animated: false)
                return
            }
            self.baseProcessHandler(
                hud: hud,
                processingMessage: NSLocalizedString("Loading", comment: "Caption of the processing"),
                status,
                message,
                error
            ) {
                if let message = message as? String {
                    hud?.setSuccessState(title: message)
                    hud?.hide(animated: false, afterDelay: .standardDelay)
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

    func download(cell: UICollectionViewCell) {
        if cell is ASCFileViewCell {
            downloadFile(cell: cell)
        } else if
            let folderCell = cell as? ASCFolderViewCell,
            let folder = folderCell.entity as? ASCFolder
        {
            downloadFolder(cell: cell, folder: folder)
        }
    }

    func downloadFile(cell: UICollectionViewCell) {
        guard
            let fileCell = cell as? ASCFileViewCell,
            let file = fileCell.entity as? ASCFile,
            let provider
        else {
            UIAlertController.showError(
                in: self,
                message: NSLocalizedString("Could not download file.", comment: "")
            )
            return
        }
        downloadFile(file: file, provider: provider)
    }

    func downloadFile(file: ASCFile, provider: ASCFileProviderProtocol) {
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
                                            documentsVC.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)

                                            // Highlight new cell
                                            delay(seconds: 0.3) {
                                                if let newCell = documentsVC.collectionView.cellForItem(at: indexPath) {
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

    func downloadFolder(cell: UICollectionViewCell?, folder: ASCFolder) {
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

    func setCustomFilter(cell: UICollectionViewCell, file: ASCFile) {
        let hud = MBProgressHUD.showTopMost()
        let requestModel = ASCCustomFilterRequestModel(enabled: !(file.customFilterEnabled ?? false))

        NetworkManagerSharedSettings().customFilter(file: file, requestModel: requestModel) { response in
            DispatchQueue.main.async {
                var successMessage: String

                switch response {
                case let .success(result):
                    if result.customFilterEnabled == true {
                        successMessage = NSLocalizedString("Custom filter for\nthe selected file\nenabled", comment: "")
                        file.customFilterEnabled = true
                    } else {
                        successMessage = NSLocalizedString("Custom filter for\nthe selected file\ndisabled", comment: "")
                        file.customFilterEnabled = false
                    }
                    hud?.setState(result: .success(successMessage))

                    if let indexPath = self.collectionView.indexPath(for: cell) {
                        self.collectionView.reloadItems(at: [indexPath])
                    }

                case let .failure(error):
                    hud?.setState(result: .failure(error.localizedDescription))
                    print(error.localizedDescription)
                }

                hud?.hide(animated: true, afterDelay: .standardDelay)
            }
        }
    }

    func copySharedLink(file: ASCFile) {
        let hud = MBProgressHUD.showTopMost()
        let successMessage = file.customFilterEnabled
            ? NSLocalizedString("The link to the file\nwith the enabled\nCustom filter is\nsuccessfully\ncopied to the\nclipboard.", comment: "Button title")
            : NSLocalizedString("Link successfully\ncopied to clipboard", comment: "Button title")

        let handleResult: (Result<String, Error>) -> Void = { result in
            switch result {
            case let .success(link):
                UIPasteboard.general.string = link
                hud?.setState(result: .success(successMessage))
            case let .failure(error):
                hud?.setState(result: .failure(error.localizedDescription))
            }
            hud?.hide(animated: true, afterDelay: .standardDelay)
        }

        if let provider = provider as? ASCOnlyofficeProvider {
            Task {
                let result = await provider.generalFileLink(file: file)
                await MainActor.run {
                    handleResult(result)
                }
            }
        } else {
            let requestModel = CreateAndCopyLinkRequestModel(access: ASCShareAccess.read.rawValue, expirationDate: nil, isInternal: false)
            NetworkManagerSharedSettings().createAndCopy(file: file, requestModel: requestModel) { result in
                handleResult(result.map { $0.sharedTo.shareLink })
            }
        }
    }

    func showVersionsHistory(file: ASCFile) {
        let versionHistoryNetworkService = ASCVersionHistoryNetworkService()
        let controller = ASCVersionHistoryRootViewController(
            file: file,
            networkService: versionHistoryNetworkService
        ) { [weak self] versionFile in
            if versionFile.version < file.version {
                versionFile.openVersionMode = true
                self?.open(file: versionFile, openMode: .view)
            } else if let self, let provider = self.provider {
                if ASCAppSettings.Feature.openViewModeByDefault {
                    let title = file.title,
                        fileExt = title.fileExtension().lowercased()

                    if file.isForm, ASCConstants.FileExtensions.forms.contains(fileExt) || ASCConstants.FileExtensions.pdf == fileExt {
                        fillForm(file: file)
                    } else if ASCConstants.FileExtensions.documents.contains(fileExt) {
                        open(file: file, openMode: .view)
                    } else if ASCConstants.FileExtensions.pdf == fileExt {
                        open(file: file, openMode: .fillform)
                    } else {
                        open(file: file, openMode: !(provider.allowEdit(entity: file) || provider.allowComment(entity: file)) ? .view : .edit)
                    }
                } else {
                    open(file: file, openMode: !provider.allowEdit(entity: file) ? .view : .edit)
                }
            }
        } download: { [weak self] versionFile in
            guard let self,
                  let provider else { return }
            self.downloadFile(file: versionFile, provider: provider)
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.modalPresentationStyle = .formSheet
        } else {
            controller.modalPresentationStyle = .popover
        }

        present(controller, animated: true)
    }

    func leaveRoom(cell: UICollectionViewCell?, folder: ASCFolder, changeOwner: Bool = false) {
        guard let provider = provider as? ASCOnlyofficeProvider else { return }

        var hud: MBProgressHUD?

        let isOwner: Bool = provider.checkRoomOwner(folder: folder)
        let alertController = UIAlertController(title: NSLocalizedString("Leave the room", comment: ""), message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel, handler: nil)
        let displayAllert = !changeOwner
        if isOwner || changeOwner {
            let changeOwnerAction = {
                self.navigator.navigate(to: .leaveRoom(entity: folder) { status, result, error in
                    if status == .begin {
                        hud = MBProgressHUD.showTopMost()
                    } else if status == .error {
                        hud?.hide(animated: true)
                        let message = changeOwner
                            ? NSLocalizedString("Couldn't change the room owner", comment: "")
                            : NSLocalizedString("Couldn't leave the room", comment: "")
                        UIAlertController.showError(
                            in: self,
                            message: message
                        )
                    } else if status == .end {
                        hud?.setSuccessState()
                        hud?.label.numberOfLines = 0
                        hud?.label.text = changeOwner
                            ? NSLocalizedString("You have changed the room owner", comment: "")
                            : NSLocalizedString("You have left the room and appointed a new owner", comment: "")
                        if changeOwner {
                            self.loadFirstPage()
                        } else if let cell = cell {
                            if let indexPath = self.collectionView.indexPath(for: cell) {
                                self.provider?.remove(at: indexPath.row)
                                self.collectionView.deleteItems(at: [indexPath])
                                if let refreshControl = self.collectionView.refreshControl {
                                    self.refresh(refreshControl)
                                }
                            }
                        } else {
                            if let previousController = self.navigationController?.viewControllers[1] as? ASCDocumentsViewController,
                               let folderItem = previousController
                               .collectionView
                               .visibleCells
                               .compactMap({ $0 as? ASCFolderViewCell })
                               .first(where: { ($0.entity as? ASCFolder)?.title == folder.title }),
                               let indexPath = previousController
                               .collectionView
                               .indexPath(for: folderItem)
                            {
                                previousController.provider?.remove(at: indexPath.row)
                                previousController.collectionView.deleteItems(at: [indexPath])

                                if let refreshControl = previousController.collectionView.refreshControl {
                                    previousController.refresh(refreshControl)
                                }

                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                        hud?.hide(animated: false, afterDelay: .standardDelay)
                    }
                })
            }
            let assignOwnerAction = UIAlertAction(title: NSLocalizedString("Assign Owner", comment: ""), style: .default) { _ in
                _ = changeOwnerAction()
            }
            alertController.message = NSLocalizedString("You are the owner of this room. Before you leave the room, you must transfer the owner’s role to another user.", comment: "")

            alertController.addAction(assignOwnerAction)
            if changeOwner {
                _ = changeOwnerAction()
            }
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
                            if let indexPath = self.collectionView.indexPath(for: cell) {
                                self.provider?.remove(at: indexPath.row)
                                self.collectionView.deleteItems(at: [indexPath])
                                if let refreshControl = self.collectionView.refreshControl {
                                    self.refresh(refreshControl)
                                }
                            }
                        } else {
                            self.navigationController?.popViewController(animated: true)
                            if let refreshControl = self.collectionView.refreshControl {
                                self.refresh(refreshControl)
                            }
                        }
                        hud?.hide(animated: false, afterDelay: .standardDelay)
                    }
                }
            }

            alertController.message = NSLocalizedString("Do you really want to leave this room? You will be able to join it again via new invitation by a room admin.", comment: "")

            alertController.addAction(submitAction)
        }

        alertController.addAction(cancelAction)
        if displayAllert {
            present(alertController, animated: true)
        }
    }

    func editRoom(folder: ASCFolder) {
        let previusIndexingValue = folder.indexing
        let vc = EditRoomViewController(folder: folder) { [weak self] editedRoom in
            guard let self else { return }
            self.folder = editedRoom

            if let refreshControl = self.collectionView.refreshControl {
                self.refresh(refreshControl)
                if let viewControllers = self.navigationController?.viewControllers,
                   let index = viewControllers.firstIndex(of: self),
                   index > 0
                {
                    let previousController = viewControllers[index - 1] as? ASCDocumentsViewController
                    previousController?.refresh(refreshControl)
                }
            }

            // If indexing changed rerender layout with correct type for edited room
            if previusIndexingValue != editedRoom.indexing {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: ASCConstants.Notifications.updateDocumentsViewLayoutType,
                        object: self.provider?.itemsViewType(for: editedRoom) ?? .list
                    )
                }
            }
        }

        vc.modalPresentationStyle = .formSheet
        vc.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize

        present(vc, animated: true, completion: nil)
    }

    func favorite(cell: UICollectionViewCell, favorite: Bool) {
        guard
            let provider = provider,
            let fileCell = cell as? ASCFileViewCell,
            let file = fileCell.entity as? ASCFile
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
                    hud?.hide(animated: false, afterDelay: .standardDelay)

                    if let indexPath = self.collectionView.indexPath(for: cell),
                       let file = entity as? ASCFile
                    {
                        updateProviderStatus(for: file, indexPath: indexPath)
                    }
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }

    func updateProviderStatus(for entity: ASCEntity, indexPath: IndexPath) {
        if let file = entity as? ASCFile {
            handleStatusUpdate(for: file, indexPath: indexPath)
        }
    }

    func handleStatusUpdate(for file: ASCFile, indexPath: IndexPath) {
        if let index = tableData.firstIndex(where: { existingEntity -> Bool in
            guard let existingFile = existingEntity as? ASCFile else { return false }
            return existingFile.id == file.id
        }) {
            let updatedIndexPath = IndexPath(row: index, section: 0)

            if categoryIsFavorite, !file.isFavorite {
                provider?.remove(at: updatedIndexPath.row)
                collectionView.deleteItems(at: [updatedIndexPath])

                showEmptyView(total < 1)
            } else {
                provider?.items[updatedIndexPath.row] = file
                collectionView.reloadItems(at: [updatedIndexPath])
            }
        }
    }

    func markAsRead(cell: UICollectionViewCell) {
        guard
            let provider,
            let entity = (cell as? ASCEntityViewCellProtocol)?.entity
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
                if let entities = result as? [AnyObject],
                   let entity = entities.first
                {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: .standardDelay)

                    if let indexPath = self.collectionView.indexPath(for: cell) {
                        if let file = entity as? ASCFile {
                            file.isNew = false
                            self.provider?.items[indexPath.row] = file
                        } else if let folder = entity as? ASCFolder {
                            folder.new = 0
                            self.provider?.items[indexPath.row] = folder
                        }

                        self.collectionView.reloadItems(at: [indexPath])
                    }
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }

    func export(cell: UICollectionViewCell) {
        guard let file = (cell as? ASCEntityViewCellProtocol)?.entity as? ASCFile else {
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

            provider?.download(file.viewUrl ?? "", to: URL(fileURLWithPath: destinationPath.rawValue), range: nil) { [weak self] result, progress, error in
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
                    file.viewUrl = destinationPath.rawValue
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

    func copy(cell: UICollectionViewCell) {
        transfer(cell: cell)
    }

    func move(cell: UICollectionViewCell) {
        transfer(cell: cell, move: true)
    }

    func recover(cell: UICollectionViewCell) {
        transfer(cell: cell, move: true)
    }

    func duplicate(cell: UICollectionViewCell) {
        guard
            let fileCell = cell as? ASCFileViewCell,
            let file = fileCell.entity as? ASCFile,
            let folder
        else { return }

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
                hud?.hide(animated: false, afterDelay: .standardDelay)

                if let indexPath = self.collectionView.indexPath(for: cell),
                   let duplicate = result as? ASCFile
                {
                    self.provider?.add(item: duplicate, at: indexPath.row)
                    UIView.performWithoutAnimation { [weak self] in
                        self?.collectionView.reloadData()
                    }

                    if let newCell = self.collectionView.cellForItem(at: indexPath) {
                        self.highlight(cell: newCell)
                    }
                } else {
                    loadFirstPage()
                }
            }
        }
    }

    func transfer(cell: UICollectionViewCell, move: Bool = false) {
        if let file = (cell as? ASCFileViewCell)?.entity as? ASCFile {
            transfer(indexes: [file.uid], move: move)
        } else if let folder = (cell as? ASCFolderViewCell)?.entity as? ASCFolder {
            transfer(indexes: [folder.uid], move: move)
        }
    }

    func more(cell: UICollectionViewCell, menuButton: UIView) {
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

    func insideTransfer(
        items: [ASCEntity],
        to folder: ASCFolder,
        move: Bool = false,
        conflictResolveType: ConflictResolveType = .skip,
        contentOnly: Bool = false,
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
            conflictResolveType: conflictResolveType,
            contentOnly: contentOnly,
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
                    hud?.hide(animated: false, afterDelay: .standardDelay)

                    completion?(items)
                }
            }
        )
    }

    func insideCheckTransfer(
        items: [ASCEntity],
        to folder: ASCFolder,
        move: Bool = false,
        complation: @escaping ((_ conflictResolveType: ConflictResolveType, _ cancel: Bool) -> Void)
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
                                complation(.overwrite, false)
                            }
                        )
                    )

                    alertController.addAction(
                        UIAlertAction(
                            title: NSLocalizedString("Skip", comment: "Button title"),
                            style: .default,
                            handler: { action in
                                complation(.skip, false)
                            }
                        )
                    )

                    alertController.addAction(
                        UIAlertAction(
                            title: ASCLocalization.Common.cancel,
                            style: .cancel,
                            handler: { action in
                                complation(.skip, true)
                            }
                        )
                    )

                    self.present(alertController, animated: true, completion: nil)
                } else {
                    complation(.skip, false)
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
            guard !items.isEmpty else {
                completion?(nil)
                return
            }

            let transferNavigationVC = ASCTransferNavigationController.instantiate(from: Storyboard.transfer)

            if UIDevice.pad {
                transferNavigationVC.modalPresentationStyle = .formSheet
                transferNavigationVC.preferredContentSize = CGSize(width: ASCConstants.Size.defaultPreferredContentSize.width, height: 520)
            }

            present(transferNavigationVC, animated: true, completion: nil)

            if let transferViewController = transferNavigationVC.topViewController as? ASCTransferViewController {
                let presenter = ASCTransferPresenter(
                    view: transferViewController,
                    provider: nil,
                    transferType: isTrash(folder) ? .recover : (move ? .move : .copy),
                    enableFillRootFolders: true,
                    folder: nil,
                    flowModel: ASCTransferFlowModel(
                        sourceFolder: folder,
                        sourceProvider: provider,
                        sourceItems: entities
                    )
                )
                transferViewController.presenter = presenter
            }

            transferNavigationVC.doneHandler = { [weak self] destProvider, destFolder, _ in
                guard
                    let strongSelf = self,
                    let provider = destProvider,
                    let folder = destFolder
                else { return }

                let isTrash = strongSelf.isTrash(folder)
                let isInsideTransfer = (strongSelf.provider?.id == provider.id) && !(strongSelf.provider is ASCGoogleDriveProvider)

                if isInsideTransfer {
                    strongSelf.insideCheckTransfer(items: items, to: folder, move: move) { conflictResolveType, cancel in
                        guard !cancel else {
                            completion?(items)
                            return
                        }

                        strongSelf.insideTransfer(items: items, to: folder, move: move, conflictResolveType: conflictResolveType) { movedEntities in
                            guard movedEntities != nil else {
                                completion?(items)
                                return
                            }

                            completion?(nil)

                            if let destVC = strongSelf.getLoadedViewController(byFolderId: folder.id, andProviderId: provider.id) {
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

                                            if !items.isEmpty, let destVC = self?.getLoadedViewController(byFolderId: destFolder.id, andProviderId: destProvider.id) {
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
                self.collectionView.reloadSections(IndexSet(integer: 0))

                self.showEmptyView(self.total < 1)
                self.updateNavBar()
            }

            self.setEditMode(false)
        }

        func insert(transferedItems items: [ASCEntity], toLoadedViewController viewController: ASCDocumentsViewController) {
            guard !items.isEmpty, let provider = viewController.provider else { return }

            provider.add(items: items, at: 0)
            provider.updateSort(completeon: { [weak viewController] _, _, _, _ in
                UIView.performWithoutAnimation { [weak viewController] in
                    viewController?.collectionView.reloadData()
                }
            })

            viewController.showEmptyView(viewController.total < 1)
            viewController.showErrorView(false)
            viewController.updateNavBar()
        }
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
                hud?.hide(animated: false, afterDelay: .standardDelay)

                if self.isTrash(self.folder) || self.folder?.rootFolderType == .archive {
                    self.provider?.cancel()
                    self.provider?.reset()
                    UIView.performWithoutAnimation { [weak self] in
                        self?.collectionView.reloadData()
                    }
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
                let generalLinkResult = await onlyofficeProvider.generalLink(forFolder: room)

                await MainActor.run {
                    switch generalLinkResult {
                    case let .success(link):
                        UIPasteboard.general.string = link
                        hud?.setState(result: .success(NSLocalizedString("Link successfully\ncopied to clipboard", comment: "Button title")))

                    case .failure:
                        hud?.setState(result: .failure(nil))
                    }

                    hud?.hide(animated: true, afterDelay: .standardDelay)
                }
            }
        }
    }

    // MARK: - Actions

    @objc func onTransformToRoomSelected(_ sender: Any) {
        let entities: [ASCEntity] = selectedIds.compactMap { uid in
            tableData.first(where: { $0.uid == uid })
        }
        guard !entities.isEmpty else { return }

        transformToRoom(entities: entities)
    }

    @objc func onCopySelected(_ sender: Any) {
        transfer(indexes: selectedIds)
    }

    @objc func onMoveSelected(_ sender: Any) {
        transfer(indexes: selectedIds, move: true)
    }

    @objc func onRoomRestore(_ sender: Any) {
        showRestoreRoomAlert { [weak self] in
            guard let self else { return }
            self.restoreRoom()
        }
    }

    @objc func onRemoveArchivedRooms(_ sender: Any) {
        let message = {
            if selectedIds.count == 1 {
                return NSLocalizedString("You are about to delete this room. You won't be able to restore it. Are you sure you want to continue?", comment: "")
            } else {
                return NSLocalizedString("You are about to delete these rooms. You won't be able to restore them. Are you sure you want to continue?", comment: "")
            }
        }()
        onTrash(
            ids: selectedIds,
            sender,
            notificationType: .deleteforeverAlert(message)
        )
    }

    @objc func onTrashSelected(_ sender: Any) {
        onTrash(ids: selectedIds, sender, notificationType: .default)
    }

    private func canRemoveLeastOneItem() -> Bool {
        canPerformActionOnLeastOneItem(fileKeyPathSecurity: \.delete, folderKeyPathSecurity: \.delete)
    }

    private func canArchiveLeastOneItem() -> Bool {
        canMoveLeastOneItem() // Archive = Move
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

    private func canArchiveAllSelectedItems() -> Bool {
        canMoveAllSelectedItems() // Archive = Move
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
            case let .deleteforeverAlert(message):
                showRemoveAlert(message: message) { [unowned self] in
                    self.removerActionController.delete(indexes: ids)
                }
            }
        }
    }

    @objc func onInfoSelected(_ sender: Any) {
        guard let provider = provider,
              let folder = tableData.first(where: {
                  selectedIds.contains($0.uid)
              }),
              selectedIds.count == 1
        else { return }
        presentShareController(provider: provider, entity: folder)
    }

    @objc func onPinSelected(_ sender: Any) {
        guard let provider = provider, selectedIds.count > 0 else { return }

        let dispatchGroup = DispatchGroup()
        var indexPathes: [IndexPath] = []
        let hud = MBProgressHUD.showTopMost()
        let isSelectedItemsPinned = isSelectedItemsPinned()
        let action: ASCEntityActions = isSelectedItemsPinned ? .unpin : .pin
        var lastError: Error?

        hud?.label.text = isSelectedItemsPinned
            ? NSLocalizedString("Unpinning", comment: "Caption of the processing")
            : NSLocalizedString("Pinning", comment: "Caption of the processing")
        tableData.filter { selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFolder }
            .forEach {
                guard let indexPath = indexPath(by: $0) else { return }
                dispatchGroup.enter()
                provider.handle(action: action, folder: $0) { status, result, error in
                    if status == .end {
                        indexPathes.append(indexPath)
                    }
                    if status == .end || status == .error {
                        if status == .error {
                            lastError = error
                        }
                        dispatchGroup.leave()
                    }
                }
            }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.updateNavBar()
            self.setEditMode(false)
            hud?.hide(animated: true, afterDelay: .oneSecondDelay)
            self.loadFirstPage()

            if let lastError {
                UIAlertController.showError(
                    in: self,
                    message: lastError.localizedDescription
                )
            }
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
            hud?.hide(animated: true, afterDelay: .oneSecondDelay)
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

    private func showRemoveAlert(message: String, handler: @escaping () -> Void) {
        let alertDelete = UIAlertController(
            title: NSLocalizedString("Delete forever?", comment: ""),
            message: message,
            preferredStyle: .alert,
            tintColor: nil
        )

        alertDelete.addCancel()

        alertDelete.addAction(
            UIAlertAction(
                title: NSLocalizedString("Delete", comment: ""),
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

    @objc func onApplyButtonTapped(_ sender: UIButton) {
        if isEditingIndexMode, let editOrderIndexDelegate = provider as? ProviderEditIndexDelegate {
            editOrderIndexDelegate.applyEditedOrderIndex { message in
                guard let message else { return }
                UIAlertController.showError(
                    in: self,
                    message: message
                )
            }
            isEditingIndexMode = false
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

// MARK: - ASCDocumentsCollectionViewDelegate

extension ASCDocumentsViewController: ASCDocumentsCollectionViewDelegate {
    func swipeActionsConfiguration(collectionView: UICollectionView?, indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let collectionView, let cell = collectionView.cellForItem(at: indexPath) as? ASCEntityViewCellProtocol else { return UISwipeActionsConfiguration() }
        return UISwipeActionsConfiguration(actions: buildCellMenu(for: cell))
    }
}

// MARK: - UIScrollViewDelegate

extension ASCDocumentsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if displaySegmentTabs {
            DispatchQueue.main.debounce(interval: 0.01) { [weak self, weak scrollView] in
                guard let self, let scrollView else { return }

                let scrollContentOffset = scrollView.contentOffset.y + self.navigationBarExtendPanelView.frame.height

                if scrollContentOffset > 2.0 {
                    UIView.animate(withDuration: 0.1, animations: { [weak self] in
                        self?.navigationBarExtendPanelView.standardAppearance()
                    })
                } else {
                    UIView.animate(withDuration: 0.1, animations: { [weak self] in
                        self?.navigationBarExtendPanelView.scrollEdgeAppearance()
                    })
                }
            }
        }

        updateTitleView(scrollView)
    }
}

// MARK: - UISearchControllerDelegate

extension ASCDocumentsViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        //
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        searchSeparator.alpha = 0
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        provider?.reset()
        UIView.performWithoutAnimation { [weak self] in
            self?.collectionView.reloadData()
        }

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

        navigationBarExtendPanelView.isHidden = false
        viewDidLayoutSubviews()
        configureNavigationItem()
        updateTitle()
    }
}

// MARK: - UISearchResultsUpdating

extension ASCDocumentsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
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

        if let refreshControl = collectionView.refreshControl {
            refresh(refreshControl)
        }
        showEmptyView(total < 1)
        updateNavBar()
        setEditMode(false)
    }

    func deleteIfNeeded(
        cell: UICollectionViewCell,
        menuButton: UIView,
        complation: @escaping (UICollectionViewCell, Bool) -> Void
    ) {
        var title: String?
        let isTrash = self.isTrash(folder)
        let cellFolder = (cell as? ASCFolderViewCell)?.entity as? ASCFolder
        let currentFolder = folder

        if isTrash {
            title = NSLocalizedString("The file will be irretrievably deleted. This action is irreversible.", comment: "")
        } else if let currentFolder, currentFolder.isThirdParty {
            title = NSLocalizedString("Note: removal from your account can not be undone.", comment: "")
        } else if let currentFolder, currentFolder.rootFolderType == .archive {
            complation(cell, true)
        }

        let alertDelete = UIAlertController(
            title: title,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )

        var message = NSLocalizedString("Delete File", comment: "Button title")

        if let cellFolder {
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
        case `default`
        case deleteforeverAlert(String)
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
    case delete(UICollectionViewCell)
    case archiveAction
}

// MARK: - UICollectionViewDelegate

extension ASCDocumentsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isEditingIndexMode else { return }

        if collectionView.isEditing {
            updateSelectedItems(indexPath: indexPath)
            return
        }

        collectionView.deselectItem(at: indexPath, animated: true)

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
        } else if let file = tableData[indexPath.row] as? ASCFile, let provider {
            if ASCAppSettings.Feature.openViewModeByDefault {
                let title = file.title,
                    fileExt = title.fileExtension().lowercased()

                if file.isForm, ASCConstants.FileExtensions.forms.contains(fileExt) || ASCConstants.FileExtensions.pdf == fileExt {
                    fillForm(file: file)
                } else if ASCConstants.FileExtensions.documents.contains(fileExt) {
                    open(file: file, openMode: .view)
                } else if ASCConstants.FileExtensions.pdf == fileExt {
                    open(file: file, openMode: .fillform)
                } else {
                    open(file: file, openMode: !(provider.allowEdit(entity: file) || provider.allowComment(entity: file)) ? .view : .edit)
                }
            } else {
                open(file: file, openMode: !provider.allowEdit(entity: file) ? .view : .edit)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView.isEditing {
            if let folder = tableData[indexPath.row] as? ASCFolder {
                selectedIds.remove(folder.uid)
            } else if let file = tableData[indexPath.row] as? ASCFile {
                selectedIds.remove(file.uid)
            }

            events.trigger(eventName: "item:didDeselect")
        }
    }

    func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        if tableData.count < total, indexPath.row == tableData.count - 1 {
            if let cell = collectionView.cellForItem(at: indexPath), cell.tag == kPageLoadingCellTag {
                return false
            }
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] suggestedActions in
            guard
                let self,
                let firstIndexPath = indexPaths.first,
                let cell = collectionView.cellForItem(at: firstIndexPath)
            else { return UIMenu() }

            if let fileCell = cell as? ASCFileViewCell {
                return self.buildFileContextMenu(for: fileCell)
            } else if let folderCell = cell as? ASCFolderViewCell {
                return self.buildFolderContextMenu(for: folderCell)
            }

            return nil
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setEditMode(true)
    }
}

// MARK: - UICollectionViewDataSource

extension ASCDocumentsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard tableData.count < total else {
            return tableData.count
        }
        return tableData.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if tableData.count > 0 {
            emptyView?.removeFromSuperview()

            if indexPath.row < tableData.count {
                if let folder = tableData[indexPath.row] as? ASCFolder {
                    guard let folderCell = collectionView.dequeueReusableCell(withReuseIdentifier: ASCFolderViewCell.identifier, for: indexPath) as? ASCFolderViewCell else {
                        return UICollectionViewCell()
                    }

                    folderCell.provider = provider
                    folderCell.entity = folder
                    folderCell.layoutType = itemsViewType
                    folderCell.dragAndDropState = isEditingIndexMode

                    return folderCell
                } else if let file = tableData[indexPath.row] as? ASCFile {
                    guard let fileCell = collectionView.dequeueReusableCell(withReuseIdentifier: ASCFileViewCell.identifier, for: indexPath) as? ASCFileViewCell else {
                        return UICollectionViewCell()
                    }

                    fileCell.provider = provider
                    fileCell.entity = file
                    fileCell.layoutType = itemsViewType
                    fileCell.dragAndDropState = isEditingIndexMode

                    return fileCell
                }
            } else {
                guard let loaderCell = collectionView.dequeueReusableCell(withReuseIdentifier: ASCLoaderViewCell.identifier, for: indexPath) as? ASCLoaderViewCell else {
                    return UICollectionViewCell()
                }

                loaderCell.tag = kPageLoadingCellTag
                loaderCell.startActivity()

                return loaderCell
            }
        }

        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell.tag == kPageLoadingCellTag {
            cell.isHidden = false
            provider?.page += 1

            fetchData { [weak self] success in
                if !success {
                    guard let self else { return }

                    self.provider?.page -= 1
                    delay(seconds: 0.6) {
                        cell.isHidden = true
                        UIView.performWithoutAnimation { [weak self] in
                            self?.collectionView.reloadData()
                        }
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

            if let fileCell = cell as? ASCFileViewCell {
                fileCell.isSelected = isSelected
            }

            if let folderCell = cell as? ASCFolderViewCell {
                folderCell.isSelected = isSelected
            }

            if isSelected {
                self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.collectionView(collectionView, didSelectItemAt: indexPath)
            }
        }
    }
}
