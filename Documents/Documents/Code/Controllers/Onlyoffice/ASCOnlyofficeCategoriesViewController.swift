//
//  ASCOnlyofficeCategoriesViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import Kingfisher

class ASCOnlyofficeCategoriesViewController: UITableViewController {

    // MARK: - Properties

    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var accountName: UILabel!
    @IBOutlet weak var accountPortal: UILabel!

    private var currentlySelectedFolderType: ASCFolderType?
    private let activityIndicator = UIActivityIndicatorView()
    private var account: ASCAccount?
    private let cacheManager: ASCOnlyofficeCacheCategoriesProvider = ASCOnlyofficeUserDefaultsCacheCategoriesProvider()
    
    private lazy var categoriesProviderFactory = ASCOnlyofficeCategoriesProviderFactory()
    private var categoriesCurrentlyLoading: Bool {
        get {
            return self.categoriesProviderFactory.get().categoriesCurrentlyLoading
        }
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
        get {
            loadedCategories.isEmpty ? cachedCategories : loadedCategories
        }
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

        if UIDevice.pad,let documentsNC = navigationController as? ASCBaseNavigationController {
            documentsNC.hasShadow = true
            documentsNC.setToolbarHidden(true, animated: false)
        }

        clearsSelectionOnViewWillAppear = UIDevice.phone

        NotificationCenter.default.addObserver(self, selector: #selector(updateUserInfo), name: ASCConstants.Notifications.userInfoOnlyofficeUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onOnlyofficeLogInCompleted(_:)), name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onOnlyofficeLogoutCompleted(_:)), name: ASCConstants.Notifications.logoutOnlyofficeCompleted, object: nil)

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
                    loadCachedCategories(provider: onlyofficeProvider)
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
        loadCategories {
            self.updateTableView()
        }
        
        updateUserInfo()
    }
    
    // MARK: - Categories loading
    func loadCategories(completion: @escaping () -> Void) {
        categoriesProviderFactory.get().loadCategories { [self] categories in
            self.loadedCategories =  categories
            completion()
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
           let account = self.account
        {
            DispatchQueue.global(qos: .background).async {
                let error = self.cacheManager.save(for: account, categories: self.categories)
                if error == nil {
                    self.cachedCategories = self.loadedCategories
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction func onUserAction(_ sender: UIButton) {
        if let splitVC = splitViewController {
            if let _ = ASCFileManager.onlyofficeProvider?.user {
                let userProfileVC = ASCUserProfileViewController.instantiate(from: Storyboard.userProfile)
                let userProfileNavigationVC = ASCBaseNavigationController(rootASCViewController: userProfileVC)

                userProfileNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
                userProfileNavigationVC.modalPresentationStyle = .formSheet

                splitVC.hideMasterController()
                splitVC.present(userProfileNavigationVC, animated: true, completion: nil)
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
                }))

                alertController.addAction(UIAlertAction(
                    title: ASCLocalization.Common.cancel,
                    style: .cancel,
                    handler: nil)
                )

                splitVC.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    private func updateTableView() {
        tableView.reloadData()
        selectCurrentlyRow()
    }
    
    // MARK: - Select row

    func select(category: ASCCategory, animated: Bool = false) {
        guard let splitVC = splitViewController else {
            return
        }
        let documentsNC = ASCDocumentsNavigationController.instantiate(from: Storyboard.main)
        if let documentsVC = documentsNC.topViewController as? ASCDocumentsViewController {
            // Pop to root
            if  let primaryViewController = (splitVC as? ASCBaseSplitViewController)?.primaryViewController,
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
                tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
            }
            self.currentlySelectedFolderType = folderType
        }
    }
}

// MARK: - Table view data source

extension ASCOnlyofficeCategoriesViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ASCOnlyofficeCategoryCell.identifier, for: indexPath) as? ASCOnlyofficeCategoryCell {
            cell.category = categories[indexPath.row]
            cell.accessoryType = (UIDevice.phone || ASCViewControllerManager.shared.currentSizeClass == .compact) ? .disclosureIndicator : .none
            return cell
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select(category: categories[indexPath.row], animated: true)
    }
}
