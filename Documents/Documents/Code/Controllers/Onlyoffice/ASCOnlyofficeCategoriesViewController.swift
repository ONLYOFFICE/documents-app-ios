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


    private var categories: [ASCOnlyofficeCategory] = []

    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        loadCategories()
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

        if categories.count < 1 {
            loadCategories()
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

        ASCViewControllerManager.shared.rootController?.tabBar.isHidden = false
        updateLargeTitlesSize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        fetchUpdateUserInfo()
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

    func loadCategories() {
        categories = []

        if let onlyoffice = ASCFileManager.onlyofficeProvider, let user = onlyoffice.user {
            categories = []

            let isPersonal = onlyoffice.api.baseUrl?.contains(ASCConstants.Urls.portalPersonal) ?? false
            let allowMy = !user.isVisitor
            let allowShare = !isPersonal
            let allowCommon = !isPersonal
            let allowProjects = !(user.isVisitor || isPersonal)

            // My Documents
            if allowMy {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeUser)
                    $0.image = UIImage(named: "category-my")
                    $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeUser)
                    return $0
                }(ASCOnlyofficeCategory()))
            }

            // Shared with Me Category
            if allowShare {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeShare)
                    $0.image = UIImage(named: "category-share")
                    $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeShare)
                    return $0
                    }(ASCOnlyofficeCategory()))
            }

            // Common Documents Category
            if allowCommon {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeCommon)
                    $0.image = UIImage(named: "category-common")
                    $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeCommon)
                    return $0
                    }(ASCOnlyofficeCategory()))
            }

            // Project Documents Category
            if allowProjects {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeProjects)
                    $0.image = UIImage(named: "category-projects")
                    $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeProjects)
                    return $0
                    }(ASCOnlyofficeCategory()))
            }

            // Trash Category
            categories.append({
                $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeTrash)
                $0.image = UIImage(named: "category-trash")
                $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeTrash)
                return $0
                }(ASCOnlyofficeCategory()))
        }
    }
    
    private func fetchUpdateUserInfo() {
        if let onlyofficeProvider = ASCFileManager.onlyofficeProvider?.copy() as? ASCOnlyofficeProvider {
            onlyofficeProvider.userInfo { [weak self] success, error in
                if let localError = error?.localizedDescription {
                    onlyofficeProvider.errorBanner(localError)
                } else if success {
                    ASCFileManager.onlyofficeProvider?.user = onlyofficeProvider.user
                    self?.updateUserInfo()
                }
            }
        }
    }

    @objc func updateUserInfo() {
        var hasInfo = false

        if let onlyofficeProvider = ASCFileManager.onlyofficeProvider?.copy() as? ASCOnlyofficeProvider {
            if let user = ASCFileManager.onlyofficeProvider?.user {
                hasInfo = true

                let avatarUrl = onlyofficeProvider.absoluteUrl(from: user.avatarRetina ?? user.avatar)

                avatarView?.kf.apiSetImage(with: avatarUrl,
                                           placeholder: UIImage(named: "avatar-default"))

                accountName?.text = user.displayName?.trim()
                accountPortal?.text = onlyofficeProvider.api.baseUrl?.trim()
            } else {
                hasInfo = false

                avatarView?.image = UIImage(named: "avatar-default")
                accountName?.text = "-"
                accountPortal?.text = "-"

                onlyofficeProvider.userInfo { [weak self] success, error in
                    if let localError = error?.localizedDescription {
                        onlyofficeProvider.errorBanner(localError)
                    } else if success {
                        ASCFileManager.onlyofficeProvider?.user = onlyofficeProvider.user
                        self?.updateUserInfo()
                    }
                }
            }
        } else {
            hasInfo = false

            avatarView?.image = UIImage(named: "avatar-default")
            accountName?.text = "-"
            accountPortal?.text = "-"
        }

        accountName?.showSkeleton(!hasInfo, animeted: true, inserts: UIEdgeInsets(top: 1, left: 0, bottom: 1, right: 50))
        accountPortal?.showSkeleton(!hasInfo, animeted: true)
    }

    @objc func onOnlyofficeLogInCompleted(_ notification: Notification) {
        loadCategories()
        updateUserInfo()
        
        tableView?.reloadData()

        if categories.count > 0 {
            tableView?.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        }
    }

    @objc func onOnlyofficeLogoutCompleted(_ notification: Notification) {
        loadCategories()
        updateUserInfo()
        tableView?.reloadData()
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

    func select(category: ASCCategory, animated: Bool = false) {
        if  let splitVC = splitViewController,
            let documentsNC = ASCDocumentsNavigationController.instantiate(from: Storyboard.main) as? ASCDocumentsNavigationController,
            let documentsVC = documentsNC.topViewController as? ASCDocumentsViewController
        {
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

            documentsVC.provider = ASCFileManager.onlyofficeProvider?.copy()
            documentsVC.folder = category.folder
            documentsVC.title = category.title

            documentsVC.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem
            documentsVC.navigationItem.leftItemsSupplementBackButton = UIDevice.pad

            if categories.count < 1 {
                loadCategories()
            }

            if let index = categories.firstIndex(where: { $0.folder?.rootFolderType == documentsVC.folder?.rootFolderType }) {
                tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
            }
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
            return cell
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select(category: categories[indexPath.row], animated: true)
    }
}
