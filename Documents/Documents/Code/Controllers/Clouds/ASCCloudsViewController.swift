//
//  ASCCloudsViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import ObservableSwift
import UIKit

class ASCCloudsViewController: UITableViewController {
    private var connected: [ASCCategory] = []
    private var login: [ASCCategory] = []

    private var cloudsSubscription: EventSubscription<Any?>?

    fileprivate let providerName: ((_ type: ASCFileProviderType) -> String) = { type in
        switch type {
        case .googledrive:
            return NSLocalizedString("Google Drive", comment: "")
        case .dropbox:
            return NSLocalizedString("Dropbox", comment: "")
        case .nextcloud:
            return NSLocalizedString("Nextcloud", comment: "")
        case .owncloud:
            return NSLocalizedString("ownCloud", comment: "")
        case .yandex:
            return NSLocalizedString("Yandex Disk", comment: "")
        case .webdav:
            return NSLocalizedString("WebDAV", comment: "")
        case .icloud:
            return NSLocalizedString("iCloud", comment: "")
        case .onedrive:
            return NSLocalizedString("OneDrive", comment: "")
        case .kdrive:
            return NSLocalizedString("kDrive", comment: "")
        default:
            return NSLocalizedString("Unknown", comment: "")
        }
    }

    fileprivate let providerImage: ((_ type: ASCFileProviderType) -> UIImage?) = { type in
        switch type {
        case .googledrive:
            return Asset.Images.cloudGoogleDrive.image
        case .dropbox:
            return Asset.Images.cloudDropbox.image
        case .nextcloud:
            return Asset.Images.cloudNextcloud.image
        case .owncloud:
            return Asset.Images.cloudOwncloud.image
        case .yandex:
            return Asset.Images.cloudYandexDisk.image
        case .webdav:
            return Asset.Images.cloudWebdav.image
        case .icloud:
            return Asset.Images.cloudIcloud.image
        case .onedrive:
            return Asset.Images.cloudOnedrive.image
        case .kdrive:
            return Asset.Images.cloudKdrive.image
        default:
            return nil
        }
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        if UIDevice.pad, let documentsNC = navigationController as? ASCBaseNavigationController {
            documentsNC.hasShadow = true
            documentsNC.setToolbarHidden(true, animated: false)
        }

        clearsSelectionOnViewWillAppear = UIDevice.phone
        loadData()
        updateLargeTitlesSize()

        ManagedAppConfig.shared.add(observer: self)
        ManagedAppConfig.shared.triggerHooks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if ASCViewControllerManager.shared.rootController?.isEditing == true {
            ASCViewControllerManager.shared.rootController?.tabBar.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    deinit {
        if let subscription = cloudsSubscription {
            ASCFileManager.observer.remove(subscription)
        }
    }

    func loadData() {
        updateMyClouds()
        updateLoginClouds()

        cloudsSubscription = ASCFileManager.observer.add(owner: self) { [weak self] objects in
            self?.tableView?.reloadData()
        }

        tableView?.reloadData()
    }

    func updateMyClouds() {
        connected = []

        for provider in ASCFileManager.cloudProviders {
            connected.append({
                $0.title = provider.user?.displayName ?? provider.user?.userId
                $0.subtitle = provider.user?.department
                $0.image = providerImage(provider.type)
                $0.provider = provider
                $0.folder = provider.rootFolder
                return $0
            }(ASCCategory()))
        }
    }

    func updateLoginClouds() {
        login = []

        var correctDefaultConnectCloudProviders = ASCConstants.Clouds.defaultConnectCloudProviders
        let allowGoogleDrive = ASCConstants.remoteConfigValue(forKey: ASCConstants.RemoteSettingsKeys.allowGoogleDrive)?.boolValue ?? true

        if !allowGoogleDrive {
            correctDefaultConnectCloudProviders.removeAll(.googledrive)
        }

        for type in correctDefaultConnectCloudProviders {
            if !connected.contains(where: { $0.provider?.type == type }) {
                login.append({
                    $0.title = providerName(type)
                    $0.image = providerImage(type)
                    $0.provider = ASCFileManager.createProvider(by: type)
                    return $0
                }(ASCCategory()))
            }
        }

        // Add category
        login.append(ASCCategory())
    }

    func onConnectComplete(provider: ASCFileProviderProtocol) {
        // Reload list info
        connectProvider(provider)
        select(provider: provider)
    }

    func presentConnectProviderView(by type: ASCFileProviderType, completion: (() -> Void)? = nil) {
        let connectStorageVC = ASCConnectCloudViewController.instantiate(from: Storyboard.connectStorage)
        let navigationVC = UINavigationController(rootViewController: connectStorageVC)

        connectStorageVC.complation = onConnectComplete
//        connectStorageVC.presentProviderConnection(by: type)

        navigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
        navigationVC.modalPresentationStyle = .formSheet

        present(navigationVC, animated: true, completion: completion)
        connectStorageVC.presentProviderConnection(by: type)
    }

    func connectProvider(_ provider: ASCFileProviderProtocol) {
        updateMyClouds()
        updateLoginClouds()

        UIView.transition(with: tableView,
                          duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: { self.tableView.reloadData() })
    }

    func disconnectProvider(_ provider: ASCFileProviderProtocol) {
        if let index = connected.firstIndex(where: { $0.provider?.id == provider.id }) {
            disconnectProvider(by: index)
        }
    }

    func disconnectProvider(by index: Int) {
        if let removedProvider = connected[index].provider,
           let removedIndex = ASCFileManager.cloudProviders.firstIndex(where: { $0.id == removedProvider.id })
        {
            ASCFileManager.cloudProviders.remove(at: removedIndex)
            ASCFileManager.storeProviders()
        }

        tableView.beginUpdates()
        connected.remove(at: index)
        if connected.count > 0 {
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        } else {
            tableView.deleteSections(IndexSet(integer: 0), with: .fade)
        }
        tableView.endUpdates()

        // Update connect list
        updateLoginClouds()

        select(provider: nil)

        if connected.count > 0 {
            tableView.reloadSections(IndexSet(integer: 1), with: .fade)
        } else {
            UIView.transition(with: tableView,
                              duration: 0.35,
                              options: .transitionCrossDissolve,
                              animations: { self.tableView.reloadData() })
        }
    }

    func displayLastSelected() {
        loadData()

        if let index = UserDefaults.standard.object(forKey: ASCConstants.SettingsKeys.lastCloudIndex) as? Int,
           index < connected.count
        {
            select(provider: connected[index].provider)
        } else {
            select(provider: nil)
        }
    }

    func select(provider: ASCFileProviderProtocol?, folder: ASCFolder? = nil, animated: Bool = false) {
        // Check Reachable
//        if let provider = provider {
//            provider.isReachable(completionHandler: { success, error in
//                DispatchQueue.main.async(execute: {
//                    if ASCFileManager.provider?.id == provider.id {
//                        if !success {
//                            ASCBanner.shared.showError(
//                                title: ASCLocalization.Common.error,
//                                message: error?.localizedDescription ?? NSLocalizedString("Selected provider is not available", comment: "")
//                            )
//                        }
//                    }
//                })
//            })
//        }

        if let splitVC = splitViewController {
            if let provider = provider,
               let documentsNC = ASCDocumentsNavigationController.instantiate(from: Storyboard.main) as? ASCDocumentsNavigationController,
               let documentsVC = documentsNC.topViewController as? ASCDocumentsViewController
            {
                let rootFolder = provider.rootFolder
                let folder = folder ?? rootFolder

                // Pop to root
                if let primaryViewController = (splitVC as? ASCBaseSplitViewController)?.primaryViewController,
                   let documentsNavigationVC = primaryViewController as? ASCCloudsNavigationController,
                   let categoriesVC = documentsNavigationVC.viewControllers.first as? ASCCloudsViewController
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

                // Open root folder if needed
                if folder.id == rootFolder.id {
                    documentsVC.provider = provider
                    documentsVC.folder = folder
                } else {
                    documentsVC.provider = provider.copy()
                    documentsVC.folder = rootFolder

                    let newDocumentsVC = ASCDocumentsViewController.instantiate(from: Storyboard.main)
                    newDocumentsVC.provider = provider
                    newDocumentsVC.folder = folder

                    documentsNC.pushViewController(newDocumentsVC, animated: false)
                }

                ASCFileManager.provider = provider

                documentsVC.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem
                documentsVC.navigationItem.leftItemsSupplementBackButton = UIDevice.pad

                if connected.count < 1 {
                    updateMyClouds()
                }

                if let index = connected.firstIndex(where: { $0.provider?.id == provider.id }) {
                    tableView?.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
                    UserDefaults.standard.set(index, forKey: ASCConstants.SettingsKeys.lastCloudIndex)
                }
            } else {
                UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.lastCloudIndex)

                if ASCViewControllerManager.shared.phoneLayout {
                    if let splitVC = splitViewController as? ASCBaseSplitViewController,
                       let documentsNC = splitVC.primaryViewController as? ASCCloudsNavigationController ?? splitVC.detailViewController as? ASCCloudsNavigationController
                    {
                        documentsNC.popToRootViewController(animated: false)
                    }
                } else {
                    let emptyCloudVC = ASCCloudsEmptyViewController.instantiate(from: Storyboard.main)
                    emptyCloudVC.onAddService = { [weak self] type in
                        guard let strongSelf = self else { return }

                        strongSelf.presentConnectProviderView(by: type) { [weak self] in
                            guard let strongSelf = self else { return }

                            if let splitVC = strongSelf.splitViewController as? ASCBaseSplitViewController,
                               let documentsNC = splitVC.detailViewController as? ASCDocumentsNavigationController,
                               let documentsVC = documentsNC.viewControllers.first as? ASCDocumentsViewController,
                               let currentProvider = documentsVC.provider,
                               let providerIndex = strongSelf.connected.firstIndex(where: { $0.provider?.id == currentProvider.id })
                            {
                                strongSelf.tableView.selectRow(at: IndexPath(row: providerIndex, section: 0), animated: true, scrollPosition: .none)
                            }
                        }
                    }

                    splitVC.showDetailViewController(UINavigationController(rootASCViewController: emptyCloudVC), sender: self)

                    if let selectedIndexPath = tableView.indexPathForSelectedRow {
                        tableView.deselectRow(at: selectedIndexPath, animated: false)
                    }
                }
            }
        }
    }
}

// MARK: - Table view data source

extension ASCCloudsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return connected.count > 0 ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return connected.count > 0 ? connected.count : login.count
        } else if section == 1 {
            return login.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellConnectedIdentifier = ASCCloudCategoryCell.identifier + "-Connected"
        let cellLoginIdentifier = ASCCloudCategoryCell.identifier + "-Login"
        let cellAddIdentifier = ASCCloudCategoryCell.identifier + "-Add"

        var category: ASCCategory?
        var cellIdentifier = cellConnectedIdentifier

        if indexPath.section == 0 {
            category = connected.count > 0 ? connected[indexPath.row] : login[indexPath.row]
            cellIdentifier = cellConnectedIdentifier

            if category?.folder == nil {
                cellIdentifier = cellLoginIdentifier

                if category?.provider == nil {
                    cellIdentifier = cellAddIdentifier
                }
            }
        } else if indexPath.section == 1 {
            category = login[indexPath.row]
            cellIdentifier = cellLoginIdentifier

            if category?.provider == nil {
                cellIdentifier = cellAddIdentifier
            }
        }

        if let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ASCCloudCategoryCell {
            var type: ASCCloudCategoryCell.ASCCloudCategoryCellType = []

            if indexPath.row == 0 {
                type.insert(.top)
            }

            if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
                type.insert(.bottom)
            }

            cell.category = category
            cell.cellType = type

            if cellIdentifier == cellConnectedIdentifier {
                cell.accessoryType = ASCViewControllerManager.shared.phoneLayout ? .disclosureIndicator : .none
            }

            return cell
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return connected.count > 0
                ? NSLocalizedString("My Clouds", comment: "")
                : NSLocalizedString("Connect Clouds", comment: "")
        } else if section == 1 {
            return NSLocalizedString("Connect Clouds", comment: "")
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var category: ASCCategory?

        if indexPath.section == 0 {
            category = connected.count > 0 ? connected[indexPath.row] : login[indexPath.row]
            tableView.cellForRow(at: indexPath)?.debounce(delay: 0.5)
        } else if indexPath.section == 1 {
            category = login[indexPath.row]
        }

        if let category = category {
            if let provider = category.provider {
                if let folder = category.folder {
                    // Display folder
                    select(provider: provider, folder: folder, animated: true)
                } else {
                    // Display connect provider
                    presentConnectProviderView(by: provider.type) { [weak self] in
                        guard let strongSelf = self else { return }

                        if let splitVC = strongSelf.splitViewController as? ASCBaseSplitViewController,
                           let documentsNC = splitVC.detailViewController as? ASCDocumentsNavigationController,
                           let documentsVC = documentsNC.viewControllers.first as? ASCDocumentsViewController,
                           let currentProvider = documentsVC.provider,
                           let providerIndex = strongSelf.connected.firstIndex(where: { $0.provider?.id == currentProvider.id })
                        {
                            strongSelf.tableView.selectRow(at: IndexPath(row: providerIndex, section: 0), animated: true, scrollPosition: .none)
                        } else {
                            strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                        }
                    }
                }
            } else {
                // Display connect unknown provider
                presentConnectProviderView(by: .unknown) { [weak self] in
                    guard let strongSelf = self else { return }

                    if let splitVC = strongSelf.splitViewController as? ASCBaseSplitViewController,
                       let documentsNC = splitVC.detailViewController as? ASCDocumentsNavigationController,
                       let documentsVC = documentsNC.viewControllers.first as? ASCDocumentsViewController,
                       let currentProvider = documentsVC.provider,
                       let providerIndex = strongSelf.connected.firstIndex(where: { $0.provider?.id == currentProvider.id })
                    {
                        strongSelf.tableView.selectRow(at: IndexPath(row: providerIndex, section: 0), animated: true, scrollPosition: .none)
                    } else {
                        strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                    }
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == 0, connected.count > 0 {
            let delete = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [weak self] action, indexPath in
                self?.disconnectProvider(by: indexPath.row)
            }
            delete.backgroundColor = ASCConstants.Colors.red
            return [delete]
        }

        return []
    }
}
