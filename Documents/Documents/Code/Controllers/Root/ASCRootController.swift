//
//  ASCRootController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import FileKit

class ASCRootController: UITabBarController {

    // MARK: - Properties
    
    var currentSizeClass: UIUserInterfaceSizeClass = .compact
    
    private var isFirstOpenDeviceCategory = false
    private var isFirstOpenOnlyofficeCategory = false
    private var isFirstOpenCloudCategory = false

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ASCCommon.isUnitTesting {
            displaySplash()
            return
        }

        delegate = self

        // Disable edit view controllers
        customizableViewControllers = nil

        // Setup view controllers
        ASCViewControllerManager.shared.rootController = self

        // Registry events
        NotificationCenter.default.addObserver(self, selector: #selector(checkShortcutLaunch), name: ASCConstants.Notifications.shortcutLaunch, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkPushInfo), name: ASCConstants.Notifications.pushInfo, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkImportLaunch), name: ASCConstants.Notifications.importFileLaunch, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(onOnlyofficeLoginCompleted(_:)), name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(onOnlyofficeLogoutCompleted(_:)), name: ASCConstants.Notifications.logoutOnlyofficeCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged), name: ASCConstants.Notifications.networkStatusChanged, object: nil)

        // Setup tabBarItem
        if let deviceSC = viewControllers?.first(where: { $0 is ASCDeviceSplitViewController }) {
            let allowFaceId = UIDevice.device.isFaceIDCapable

            if UIDevice.pad {
                deviceSC.tabBarItem.title = NSLocalizedString("On iPad", comment: "")
                deviceSC.tabBarItem.image = allowFaceId ? UIImage(named: "tab-ipad-new") : UIImage(named: "tab-ipad")
            } else {
                deviceSC.tabBarItem.title = NSLocalizedString("On iPhone", comment: "")
                deviceSC.tabBarItem.image = allowFaceId ? UIImage(named: "tab-iphone-x") : UIImage(named: "tab-iphone")
            }
        }

        if let onlyofficeSC = viewControllers?.first(where: { $0 is ASCOnlyofficeSplitViewController }) {
            onlyofficeSC.tabBarItem.title = ASCConstants.Name.appNameShort
        }
        
        update(traitCollection: traitCollection)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        update(traitCollection: traitCollection)
    }
    
    private func update(traitCollection: UITraitCollection) {
        if currentSizeClass != traitCollection.horizontalSizeClass && UIDevice.pad {
            currentSizeClass = traitCollection.horizontalSizeClass
            NotificationCenter.default.post(name: ASCConstants.Notifications.updateSizeClass, object: currentSizeClass)
        }
    }

    private func displaySplash() {
        if let splashVC = storyboard?.instantiateViewController(withIdentifier: "ASCSplashViewController") {
            UIApplication.shared.windows.last?.rootViewController = splashVC
        }
    }
    
    func display(provider: ASCFileProviderProtocol?, folder: ASCFolder?) {
        guard let provider = provider else { return }
        
        if provider.type == .local {
            if let index = viewControllers?.firstIndex(where: { $0 is ASCDeviceSplitViewController }) {
                selectedIndex = index

                if  let splitVC = selectedViewController as? ASCDeviceSplitViewController,
                    let categoryNC = splitVC.primaryViewController as? ASCBaseNavigationController,
                    let categoryVC = categoryNC.topViewController as? ASCDeviceCategoryViewController ?? categoryNC.viewControllers.first as? ASCDeviceCategoryViewController
                {
                    if let folder = folder {
                        isFirstOpenDeviceCategory = true
                        
                        if folder.rootFolderType == .deviceTrash {
                            categoryVC.select(category: categoryVC.deviceTrashCategory)
                        } else {
                            categoryVC.select(category: categoryVC.deviceDocumentsCategory)

                            if folder.parentId != nil {
                                if let documentsNC = splitVC.detailViewController as? ASCBaseNavigationController {
                                    let documentsVC = ASCDocumentsViewController.instantiate(from: Storyboard.main)
                                    documentsVC.provider = ASCFileManager.localProvider
                                    documentsVC.folder = folder
                                    documentsNC.pushViewController(documentsVC, animated: false)
                                }
                            }
                        }
                    } else {
                        categoryVC.select(category: categoryVC.deviceDocumentsCategory)
                    }
                }
            }
        } else if provider.type == .onlyoffice {
            if let index = viewControllers?.firstIndex(where: { $0 is ASCOnlyofficeSplitViewController }) {
                selectedIndex = index

                if  let splitVC = selectedViewController as? ASCOnlyofficeSplitViewController,
                    let categoryNC = splitVC.primaryViewController as? ASCBaseNavigationController,
                    let categoryVC = categoryNC.viewControllers.first(where: { $0 is ASCOnlyofficeCategoriesViewController }) as? ASCOnlyofficeCategoriesViewController
                {
                    isFirstOpenOnlyofficeCategory = true
                    
                    if let folder = folder {
                        let category: ASCOnlyofficeCategory = {
                            $0.title = ASCOnlyofficeCategory.title(of: folder.rootFolderType)
                            $0.folder = ASCOnlyofficeCategory.folder(of: folder.rootFolderType)
                            return $0
                        }(ASCOnlyofficeCategory())

                        /// Display root folder of category
                        categoryVC.select(category: category)

                        /// Display stored folder if needed
                        delay(seconds: 0.01) {
                            if !(ASCFileManager.onlyofficeProvider?.isRoot(folder: folder) ?? false) {
                                if  let documentsNC = splitVC.detailViewController as? ASCBaseNavigationController ?? splitVC.primaryViewController as? ASCBaseNavigationController
                                {
                                    let documentsVC = ASCDocumentsViewController.instantiate(from: Storyboard.main)
                                    documentsNC.pushViewController(documentsVC, animated: false)
                                    documentsVC.provider = ASCFileManager.onlyofficeProvider
                                    documentsVC.folder = folder
                                }
                            }
                        }
                    } else {
                        categoryVC.select(category: categoryVC.entrypointCategory())
                    }
                }
            }
        } else {
            if let index = viewControllers?.firstIndex(where: { $0 is ASCCloudsSplitViewController }) {
                selectedIndex = index

                if let splitVC = selectedViewController as? ASCCloudsSplitViewController,
                    let categoryVC = splitVC.primaryViewController?.topMostViewController() as? ASCCloudsViewController
                {
                    isFirstOpenCloudCategory = true
                    let cloudProvider = ASCFileManager.cloudProviders.first(where: { $0.id == provider.id })
                    categoryVC.select(provider: cloudProvider, folder: folder ?? cloudProvider?.rootFolder)
                }
            }
        }
    }

    // MARK: - Notification handlers

    @objc func checkShortcutLaunch() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let createFile: () -> Void = {
                if  ASCEditorManager.shared.isOpenedFile,
                    let rootKeyWindowVC = UIApplication.shared.keyWindow?.rootViewController
                {
                    UIAlertController.showWarning(
                        in: rootKeyWindowVC.topMostViewController(),
                        message: NSLocalizedString("Close the document before opening a new one.", comment: "")
                    )
                    return
                }
                
                var fileExt: String? = nil

                if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewDocument) {
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.forceCreateNewDocument)
                    fileExt = "docx"
                } else if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewSpreadsheet) {
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.forceCreateNewSpreadsheet)
                    fileExt = "xlsx"
                } else if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewPresentation) {
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.forceCreateNewPresentation)
                    fileExt = "pptx"
                }

                guard let fileExtension = fileExt else {
                    return
                }

                if let rootVC = ASCViewControllerManager.shared.rootController {
                    rootVC.display(provider: ASCFileManager.localProvider, folder: nil)

                    if  let splitVC = rootVC.topMostViewController() as? ASCDeviceSplitViewController,
                        let documentsNC = splitVC.viewControllers.last as? ASCBaseNavigationController,
                        let documentsVC = documentsNC.topViewController as? ASCDocumentsViewController,
                        let provider = documentsVC.provider
                    {
                        delay(seconds: 0.3, completion: {
                            ASCCreateEntity().createFile(fileExtension, for: provider, in: documentsVC)
                        })
                    }
                }
            }

            if appDelegate.passcodeLockPresenter.isPasscodePresented {
                appDelegate.passcodeLockPresenter.passcodeLockVC.dismissCompletionCallback = {
                    appDelegate.passcodeLockPresenter.dismissPasscodeLock()
                    delay(seconds: 0.3, completion: {
                        createFile()
                    })
                }
            } else {
                delay(seconds: 0.3, completion: {
                    createFile()
                })
            }
        }
    }

    @objc func checkPushInfo() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let handlePushInfo: () -> Void = {
                if let userInfo = UserDefaults.standard.dictionary(forKey: ASCConstants.SettingsKeys.pushUserInfo) {
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.pushUserInfo)

                    if let stringUrl = userInfo["url"] as? String {
                        if let url = URL(string: stringUrl) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                }
            }


            if appDelegate.passcodeLockPresenter.isPasscodePresented {
                appDelegate.passcodeLockPresenter.passcodeLockVC.dismissCompletionCallback = {
                    appDelegate.passcodeLockPresenter.dismissPasscodeLock()
                    handlePushInfo()
                }
            } else {
                handlePushInfo()
            }
        }
    }

    @objc func checkImportLaunch() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let importFile: () -> Void = { [weak self] in
                if let url = UserDefaults.standard.url(forKey: ASCConstants.SettingsKeys.importFile) {
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.importFile)

                    let fileTitle = url.lastPathComponent
                    let filePath = Path(url.path)
                    
                    if filePath.exists {
                        self?.display(provider: ASCFileManager.localProvider, folder: nil)
                        
                        delay(seconds: 0.2) {
                            var documentsVC: ASCDocumentsViewController? = self?.topMostViewController() as? ASCDocumentsViewController
                            
                            if documentsVC == nil {
                                if  let splitVC = self?.topMostViewController() as? ASCDeviceSplitViewController,
                                    let documentsNC = splitVC.viewControllers.last as? ASCBaseNavigationController {
                                    documentsVC = documentsNC.topViewController as? ASCDocumentsViewController
                                }
                            }
                            
                            if  let documentsVC = documentsVC,
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
                                }
                            }
                        }
                    }
                }
            }

            if appDelegate.passcodeLockPresenter.isPasscodePresented {
                appDelegate.passcodeLockPresenter.passcodeLockVC.dismissCompletionCallback = {
                    appDelegate.passcodeLockPresenter.dismissPasscodeLock()
                    importFile()
                }
            } else {
                importFile()
            }
        }
    }

//    @objc func onOnlyofficeLoginCompleted(_ notification: Notification) {
//        if let user = ASCFileManager.onlyofficeProvider?.user, user.isVisitor {
//            display(provider: ASCFileManager.onlyofficeProvider, folder: ASCOnlyofficeCategory.folder(of: .onlyofficeShare))
//        } else {
//            display(provider: ASCFileManager.onlyofficeProvider, folder: ASCOnlyofficeCategory.folder(of: .onlyofficeUser))
//        }
//    }

//    @objc func onOnlyofficeLogoutCompleted(_ notification: Notification) {
//        display(provider: ASCFileManager.localProvider, folder: nil)
//    }

    @objc func networkStatusChanged() {
        if !ASCNetworkReachability.shared.isReachable {
            ASCBanner.shared.showError(
                title: NSLocalizedString("No network", comment: ""),
                message: NSLocalizedString("Check your internet connection", comment: "")
            )
        }
    }
}

// MARK: - UITabBarController Delegate

extension ASCRootController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
//        print("tabBarController didSelect")
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let viewController = viewController as? ASCBaseSplitViewController {
            if selectedViewController == viewController {
                if UIDevice.phone {
                    if let detailNC = viewController.detailViewController as? UINavigationController {
                        detailNC.popToRootViewController(animated: true)
                    }
                    if let primaryNC = viewController.primaryViewController as? UINavigationController {
                        primaryNC.popToRootViewController(animated: true)
                    }
                } else {
                    if let detailNC = viewController.detailViewController as? UINavigationController {
                        detailNC.popToRootViewController(animated: true)
                    }
                }
            } else {
                if viewController.detailViewController == nil || ((viewController.detailViewController as? ASCDocumentsViewController) != nil) {
                    
                    /// Display detail VC
                    
                    if let deviceSC = viewController as? ASCDeviceSplitViewController,
                        let categoryVC = deviceSC.primaryViewController?.topMostViewController() as? ASCDeviceCategoryViewController {
                        
                        if isFirstOpenDeviceCategory { return true }
                        isFirstOpenDeviceCategory = true
                        
                        categoryVC.select(category: categoryVC.deviceDocumentsCategory)
                    } else if let deviceSC = viewController as? ASCOnlyofficeSplitViewController,
                        let categoryVC = deviceSC.primaryViewController?.topMostViewController() as? ASCOnlyofficeCategoriesViewController {
                        let category: ASCOnlyofficeCategory = {
                            $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeUser)
                            $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeUser)
                            return $0
                        }(ASCOnlyofficeCategory())
                        
                        if isFirstOpenOnlyofficeCategory { return true }
                        isFirstOpenOnlyofficeCategory = true
                        
                        categoryVC.select(category: category)
                    } else if let deviceSC = viewController as? ASCCloudsSplitViewController {
                        if deviceSC.detailViewController == nil || ((deviceSC.detailViewController as? ASCDocumentsViewController) != nil),
                            let categoryNC = deviceSC.primaryViewController as? ASCCloudsNavigationController
                        {
                            if let categoryVC = categoryNC.topViewController as? ASCCloudsViewController {
                                
                                if isFirstOpenCloudCategory { return true }
                                isFirstOpenCloudCategory = true
                                
                                categoryVC.displayLastSelected()
                            } else if (categoryNC.topViewController as? ASCDocumentsViewController) == nil {
                                categoryNC.popToRootViewController(animated: false)
                            }
                        }
                    }
                }
            }
        }

        return true
    }
}
