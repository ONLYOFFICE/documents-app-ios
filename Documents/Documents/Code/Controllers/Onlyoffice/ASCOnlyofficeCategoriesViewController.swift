//
//  ASCOnlyofficeCategoriesViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import UIKit

class ASCOnlyofficeCategoriesViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet var avatarView: UIImageView!
    @IBOutlet var accountName: UILabel!
    @IBOutlet var accountPortal: UILabel!

    private var currentlySelectedFolderType: ASCFolderType?
    private let activityIndicator = UIActivityIndicatorView()
    private var account: ASCAccount?
    private let cacheManager: ASCOnlyofficeCacheCategoriesProvider = ASCOnlyofficeUserDefaultsCacheCategoriesProvider()

    private lazy var categoriesProviderFactory: ASCOnlyofficeCategoriesProviderFactoryProtocol = ASCOnlyofficeCategoriesProviderFactory()
    private var categoriesCurrentlyLoading: Bool {
        return categoriesProviderFactory.get().categoriesCurrentlyLoading
    }

    private var categoriesGrouper: ASCOnlyofficeCategoriesGrouper {
        categoriesProviderFactory.getCategoriesGrouper()
    }

    private var cachedCategories: [ASCOnlyofficeCategory] {
        didSet {
            if !cachedCategories.isEmpty {
                hideActivityIndicator()
            }
        }
    }

    private var loadedCategories: [ASCOnlyofficeCategory] {
        didSet {
            if !loadedCategories.isEmpty {
                hideActivityIndicator()
            }
            if needUpdateCategoriesCache {
                updateCategoriesCache()
            }
        }
    }

    private var categories: [ASCOnlyofficeCategory] {
        loadedCategories.isEmpty ? cachedCategories : loadedCategories
    }

    private var groupedCategroies: ASCOnlyofficeCategoriesGroup {
        categoriesGrouper.group(categories: categories)
    }

    private var needUpdateCategoriesCache: Bool {
        guard !loadedCategories.isEmpty else { return false }
        return cachedCategories != loadedCategories
    }

    private var needReloadTableViewDataWhenViewLoaded = false

    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        cachedCategories = []
        loadedCategories = []

        super.init(coder: aDecoder)

        needReloadTableViewDataWhenViewLoaded = true
        loadCategories { [self] in
            if viewIfLoaded != nil {
                updateTableView()
            } else {
                needReloadTableViewDataWhenViewLoaded = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        avatarView?.kf.indicatorType = .activity

        if UIDevice.pad, let documentsNC = navigationController as? ASCBaseNavigationController {
            documentsNC.hasShadow = true
            documentsNC.setToolbarHidden(true, animated: false)
        }

        clearsSelectionOnViewWillAppear = UIDevice.phone

        let addObserver: (Notification.Name, Selector) -> Void = { name, selector in
            NotificationCenter.default.addObserver(
                self,
                selector: selector,
                name: name,
                object: nil
            )
        }

        addObserver(ASCConstants.Notifications.userInfoOnlyofficeUpdate, #selector(updateUserInfo))
        addObserver(ASCConstants.Notifications.loginOnlyofficeCompleted, #selector(onOnlyofficeLogInCompleted(_:)))
        addObserver(ASCConstants.Notifications.logoutOnlyofficeCompleted, #selector(onOnlyofficeLogoutCompleted(_:)))

        if loadedCategories.isEmpty, !categoriesCurrentlyLoading {
            loadCategories {
                self.updateTableView()
            }
        }

        if needReloadTableViewDataWhenViewLoaded {
            updateTableView()
        }

        updateUserInfo()
        fetchUpdateUserInfo()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        title = ASCConstants.Name.appNameShort
        navigationItem.backBarButtonItem?.title = ASCConstants.Name.appNameShort
        navigationItem.title = ASCConstants.Name.appNameShort

        if ASCViewControllerManager.shared.rootController?.isEditing == true {
            ASCViewControllerManager.shared.rootController?.tabBar.isHidden = true
        }
        updateLargeTitlesSize()

        if categories.isEmpty {
            showActivityIndicator()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        fetchUpdateUserInfo()
    }

    // MARK: - Categories activity indicator

    private func showActivityIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false

            self.view.addSubview(self.activityIndicator)

            let tableHeaderHeigh = self.tableView.tableHeaderView?.height ?? 0

            self.activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor,
                                                            constant: -tableHeaderHeigh - self.activityIndicator.height).isActive = true
            self.activityIndicator.anchorCenterXToSuperview()
            self.activityIndicator.startAnimating()
        }
    }

    private func hideActivityIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }

    func entrypointCategory() -> ASCOnlyofficeCategory {
        var folderType: ASCFolderType = .onlyofficeUser

        if let onlyoffice = ASCFileManager.onlyofficeProvider, let user = onlyoffice.user {
            if user.isVisitor {
                folderType = .onlyofficeShare
            }
        }

        return {
            $0.title = ASCOnlyofficeCategory.title(of: folderType)
            $0.folder = ASCOnlyofficeCategory.folder(of: folderType)
            return $0
        }(ASCOnlyofficeCategory())
    }

    private func fetchUpdateUserInfo() {
        if let onlyofficeProvider = ASCFileManager.onlyofficeProvider?.copy() as? ASCOnlyofficeProvider {
            onlyofficeProvider.userInfo { [weak self] success, error in
                if let error = error {
                    onlyofficeProvider.errorBanner(error)
                } else if success {
                    ASCFileManager.onlyofficeProvider?.user = onlyofficeProvider.user
                    self?.updateUserInfo()
                }
            }
        }
    }

    // MARK: - Evenet handlers

    @objc func updateUserInfo() {
        var hasInfo = false

        if let onlyofficeProvider = ASCFileManager.onlyofficeProvider?.copy() as? ASCOnlyofficeProvider {
            if let user = ASCFileManager.onlyofficeProvider?.user {
                hasInfo = true

                let avatarUrl = onlyofficeProvider.absoluteUrl(from: user.avatarRetina ?? user.avatar)

                avatarView?.kf.apiSetImage(with: avatarUrl,
                                           placeholder: Asset.Images.avatarDefault.image)

                accountName?.text = user.displayName?.trimmed

                let accountPortal = onlyofficeProvider.apiClient.baseURL?.absoluteString.trimmed
                self.accountPortal?.text = accountPortal

                if let accountEmail = user.email,
                   let accountPortalUnwraped = accountPortal,
                   let account = ASCAccount(JSON: ["email": accountEmail, "portal": accountPortalUnwraped])
                {
                    self.account = account
                    
                    // MARK: - turn off cache 
                    // loadCachedCategories(provider: onlyofficeProvider)
                }
            } else {
                hasInfo = false

                avatarView?.image = Asset.Images.avatarDefault.image
                accountName?.text = "-"
                accountPortal?.text = "-"

                onlyofficeProvider.userInfo { [weak self] success, error in
                    if let error = error {
                        onlyofficeProvider.errorBanner(error)
                    } else if success {
                        ASCFileManager.onlyofficeProvider?.user = onlyofficeProvider.user
                        self?.updateUserInfo()
                    }
                }
            }
        } else {
            hasInfo = false

            avatarView?.image = Asset.Images.avatarDefault.image
            accountName?.text = "-"
            accountPortal?.text = "-"
        }

        accountName?.showSkeleton(!hasInfo, animeted: true, inserts: UIEdgeInsets(top: 1, left: 0, bottom: 1, right: 50))
        accountPortal?.showSkeleton(!hasInfo, animeted: true)
    }

    @objc func onOnlyofficeLogInCompleted(_ notification: Notification) {
        loadCategories { [self] in
            updateTableView()

            if categories.count > 0, currentlySelectedFolderType == nil {
                tableView?.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
            }
        }
        updateUserInfo()
    }

    @objc func onOnlyofficeLogoutCompleted(_ notification: Notification) {
        if ASCAppSettings.Feature.allowCategoriesSkeleton {
            loadedCategories = []
            skeleton(show: true)
        } else {
            cachedCategories = []
            loadedCategories = []
        }
        updateUserInfo()
    }

    // MARK: - Categories loading

    func loadCategories(completion: @escaping () -> Void) {
        categoriesProviderFactory.get().loadCategories { [self] result in
            switch result {
            case let .success(categories):
                self.loadedCategories = categories
                completion()
            case let .failure(error):
                guard
                    let error = error as? NetworkingError, case .cancelled = error
                else {
                    UIAlertController.showError(in: self, message: error.localizedDescription)
                    return
                }
            }
        }
    }

    private func loadCachedCategories(provider: ASCFileProviderProtocol) {
        guard categories.isEmpty, let account = account else {
            return
        }

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            let cachedCategories = self.cacheManager.getCategories(for: account)

            if self.categories.isEmpty, !cachedCategories.isEmpty {
                self.cachedCategories = cachedCategories
                DispatchQueue.main.async {
                    self.updateTableView()
                }
            }
        }
    }

    private func updateCategoriesCache() {
        if !loadedCategories.isEmpty,
           cachedCategories != loadedCategories,
           let account = account
        {
            DispatchQueue.global(qos: .background).async {
                let error = self.cacheManager.save(for: account, categories: self.categories)
                if error == nil {
                    self.cachedCategories = self.loadedCategories
                }
            }
        }
    }

    private func skeleton(show: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.isUserInteractionEnabled = !show
            self?.tableView.visibleCells.forEach { cell in
                let contentUI = cell.subviews(ofType: UILabel.self) + cell.subviews(ofType: UIImageView.self)
                contentUI.forEach { view in
                    view.showSkeleton(show, animeted: true)
                    if let label = view as? UILabel {
                        if #available(iOS 13.0, *) {
                            label.textColor = show ? .clear : .label
                        } else {
                            label.textColor = show ? .clear : .black
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction func onUserAction(_ sender: UIButton) {
        if let splitVC = splitViewController {
            if let _ = ASCFileManager.onlyofficeProvider?.user {
                let multiProfileVC = ASCMultiAccountsViewController(style: .insetGrouped)
                let presenter = ASCMultiAccountPresenter(view: multiProfileVC)
                multiProfileVC.presenter = presenter
                let multiProfileNavigationVC = ASCBaseNavigationController(rootASCViewController: multiProfileVC)
                if UIDevice.phone {
                    multiProfileNavigationVC.modalPresentationStyle = .fullScreen
                }

                splitVC.hideMasterController()
                splitVC.present(multiProfileNavigationVC, animated: true, completion: nil)

            } else {
                let alertController = UIAlertController(
                    title: ASCLocalization.Common.error,
                    message: NSLocalizedString("No information about the user profile.", comment: ""),
                    preferredStyle: .alert,
                    tintColor: nil
                )

                alertController.addAction(UIAlertAction(
                    title: NSLocalizedString("Logout", comment: "Button title"),
                    style: .destructive,
                    handler: { action in
                        ASCUserProfileViewController.logout()
                    }
                ))

                alertController.addAction(UIAlertAction(
                    title: ASCLocalization.Common.cancel,
                    style: .cancel,
                    handler: nil
                )
                )

                splitVC.present(alertController, animated: true, completion: nil)
            }
        }
    }

    private func updateTableView() {
        tableView.reloadData()
        selectCurrentlyRow()

        if ASCAppSettings.Feature.allowCategoriesSkeleton {
            skeleton(show: categoriesCurrentlyLoading)
        }
    }

    // MARK: - Select row

    func select(category: ASCCategory, animated: Bool = false) {
        guard let splitVC = splitViewController else {
            return
        }
        let documentsNC = ASCDocumentsNavigationController.instantiate(from: Storyboard.main)
        if let documentsVC = documentsNC.topViewController as? ASCDocumentsViewController {
            // Pop to root
            if let primaryViewController = (splitVC as? ASCBaseSplitViewController)?.primaryViewController,
               let documentsNavigationVC = primaryViewController as? ASCOnlyofficeNavigationController,
               let categoriesVC = documentsNavigationVC.viewControllers.first as? ASCOnlyofficeCategoriesViewController
            {
                documentsNavigationVC.viewControllers = [categoriesVC]
            }

            if animated {
                splitVC.showDetailViewController(documentsNC, sender: self)
            } else {
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        splitVC.showDetailViewController(documentsNC, sender: self)
                    }
                }
            }

            splitVC.hideMasterController()

            let onlyOfficeProvider = ASCFileManager.onlyofficeProvider?.copy() as? ASCOnlyofficeProvider
            onlyOfficeProvider?.category = category
            documentsVC.provider = onlyOfficeProvider
            documentsVC.folder = category.folder
            documentsVC.title = category.title

            documentsVC.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem
            documentsVC.navigationItem.leftItemsSupplementBackButton = UIDevice.pad

            if loadedCategories.isEmpty {
                currentlySelectedFolderType = documentsVC.folder?.rootFolderType
                if !categoriesCurrentlyLoading {
                    loadCategories {
                        self.updateTableView()
                    }
                }
            } else {
                selectRow(with: documentsVC.folder?.rootFolderType)
            }
        }
    }

    func selectCurrentlyRow() {
        if let folderType = currentlySelectedFolderType {
            selectRow(with: folderType)
        }
    }

    func selectRow(with folderType: ASCFolderType?) {
        if let index = categories.firstIndex(where: { $0.folder?.rootFolderType == folderType }) {
            if UIDevice.pad {
                switch groupedCategroies {
                case .notGroupd:
                    tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
                case let .titledGroups(groups):
                    for (groupIndex, categories) in groups.map({ $0.categories }).enumerated() {
                        if let categoryIndex = categories.firstIndex(where: { $0.folder?.rootFolderType == folderType }) {
                            tableView.selectRow(at: IndexPath(row: categoryIndex, section: groupIndex), animated: false, scrollPosition: .none)
                            break
                        }
                    }
                }
            }
            currentlySelectedFolderType = folderType
        }
    }
}

// MARK: - Table view data source

extension ASCOnlyofficeCategoriesViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch groupedCategroies {
        case .notGroupd:
            return 1
        case let .titledGroups(groups):
            return groups.count
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch groupedCategroies {
        case let .notGroupd(categories):
            return categories.count
        case let .titledGroups(groups):
            return groups[section].categories.count
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch groupedCategroies {
        case .notGroupd, .titledGroups:
            return .leastNonzeroMagnitude
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ASCOnlyofficeCategoryCell.identifier, for: indexPath) as? ASCOnlyofficeCategoryCell {
            cell.category = getCategory(by: indexPath)
            cell.accessoryType = (UIDevice.phone || ASCViewControllerManager.shared.currentSizeClass == .compact) ? .disclosureIndicator : .none
            return cell
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select(category: getCategory(by: indexPath), animated: true)
    }

    private func getCategory(by indexPath: IndexPath) -> ASCOnlyofficeCategory {
        switch groupedCategroies {
        case let .notGroupd(categories):
            guard categories.count > indexPath.row else {
                return .init()
            }
            return categories[indexPath.row]
        case let .titledGroups(groups):
            guard groups.count > indexPath.section,
                  groups[indexPath.section].categories.count > indexPath.row
            else {
                return .init()
            }
            return groups[indexPath.section].categories[indexPath.row]
        }
    }
}
