//
//  ASCRootViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import FileKit
import UIKit

class ASCRootViewController: ASCBaseTabBarController {
    // MARK: - Properties

    override class var storyboard: Storyboard { return Storyboard.main }

    var currentSizeClass: UIUserInterfaceSizeClass = .compact

    private var isFirstOpenDeviceCategory = false
    private var isFirstOpenOnlyofficeCategory = false
    private var isFirstOpenCloudCategory = false

    var isUserInteractionEnabled: Bool = true {
        didSet {
            tabBar.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }

    // MARK: - Lifecycle Methods

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

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
//        NotificationCenter.default.addObserver(self, selector: #selector(onOnlyofficeLoginCompleted(_:)), name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(onOnlyofficeLogoutCompleted(_:)), name: ASCConstants.Notifications.logoutOnlyofficeCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged), name: ASCConstants.Notifications.networkStatusChanged, object: nil)

        // Setup tabBarItem
        if let deviceSC = viewControllers?.first(where: { $0 is ASCDeviceSplitViewController }) {
            let allowFaceId = UIDevice.device.isFaceIDCapable

            if UIDevice.pad {
                deviceSC.tabBarItem.title = NSLocalizedString("On iPad", comment: "")
                deviceSC.tabBarItem.image = allowFaceId ? Asset.Images.tabIpadNew.image : Asset.Images.tabIpad.image
            } else {
                deviceSC.tabBarItem.title = NSLocalizedString("On iPhone", comment: "")
                deviceSC.tabBarItem.image = allowFaceId ? Asset.Images.tabIphoneX.image : Asset.Images.tabIphone.image

                if Device.current.hasDynamicIsland {
                    deviceSC.tabBarItem.image = Asset.Images.tabIphoneIsland.image
                }
            }
        }

        if let onlyofficeSC = viewControllers?.first(where: { $0 is ASCOnlyofficeSplitViewController }) {
            onlyofficeSC.tabBarItem.title = ASCConstants.Name.appNameShort
        }

        if #available(iOS 15.0, *), UIDevice.pad {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()

            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = tabBar.standardAppearance
        }

        update(traitCollection: traitCollection)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
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
        if currentSizeClass != traitCollection.horizontalSizeClass, UIDevice.pad {
            currentSizeClass = traitCollection.horizontalSizeClass
            NotificationCenter.default.post(name: ASCConstants.Notifications.updateSizeClass, object: currentSizeClass)
        }
    }

    private func displaySplash() {
        UIApplication.shared.windows.last?.rootViewController = StoryboardScene.Main.ascSplashViewController.instantiate()
    }

    private func navigateLocalProvider(to folder: ASCFolder?) {
        if selectTab(ofType: ASCDeviceSplitViewController.self) {
            if let splitVC = selectedViewController as? ASCDeviceSplitViewController,
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
                            delay(seconds: 0.01) {
                                if let documentsNC = splitVC.detailViewController as? ASCBaseNavigationController {
                                    let documentsVC = ASCDocumentsViewController.instantiate(from: Storyboard.main)
                                    documentsVC.provider = ASCFileManager.localProvider.copy()
                                    documentsVC.folder = folder
                                    documentsNC.pushViewController(documentsVC, animated: false)
                                }
                            }
                        }
                    }
                } else {
                    categoryVC.select(category: categoryVC.deviceDocumentsCategory)
                }
            }
        }
    }

    private func navigateOnlyofficeProvider(to folder: ASCFolder?, inCategory categoryType: ASCFolderType? = nil) {
        if selectTab(ofType: ASCOnlyofficeSplitViewController.self) {
            if let splitVC = selectedViewController as? ASCOnlyofficeSplitViewController,
               let categoryNC = splitVC.primaryViewController as? ASCBaseNavigationController,
               let categoryVC = categoryNC.viewControllers.first(where: { $0 is ASCOnlyofficeCategoriesViewController }) as? ASCOnlyofficeCategoriesViewController
            {
                isFirstOpenOnlyofficeCategory = true

                if let folder = folder {
                    let category: ASCOnlyofficeCategory = {
                        guard let categoryType,
                              let category = categoryVC.category(ofType: categoryType)
                        else { return ASCOnlyofficeCategory(folder: folder) }
                        return category
                    }()

                    /// Display root folder of category
                    categoryVC.select(category: category)

                    /// Display stored folder if needed
                    delay(seconds: 0.01) {
                        if !(ASCFileManager.onlyofficeProvider?.isRoot(folder: folder) ?? false) {
                            if let documentsNC = splitVC.detailViewController as? ASCBaseNavigationController ?? splitVC.primaryViewController as? ASCBaseNavigationController {
                                let documentsVC = ASCDocumentsViewController.instantiate(from: Storyboard.main)
                                documentsVC.provider = ASCFileManager.onlyofficeProvider
                                documentsVC.folder = folder
                                documentsNC.pushViewController(documentsVC, animated: false)
                            }
                        }
                    }
                } else {
                    categoryVC.select(category: categoryVC.entrypointCategory())
                }
            }
        }
    }

    private func navigateiCloudProvider(to folder: ASCFolder?) {
        if selectTab(ofType: ASCCloudsSplitViewController.self) {
            if let splitVC = selectedViewController as? ASCCloudsSplitViewController,
               let categoryVC = splitVC.primaryViewController?.topMostViewController() as? ASCCloudsViewController
            {
                isFirstOpenCloudCategory = true
                let cloudProvider = ASCFileManager.cloudProviders.first(where: { $0 is ASCiCloudProvider })
                categoryVC.select(provider: cloudProvider, folder: folder ?? cloudProvider?.rootFolder)
            }
        }
    }

    @discardableResult
    func selectTab<T>(ofType: T.Type) -> Bool {
        if let tabIndex = viewControllers?.firstIndex(where: { $0 is T }) {
            selectedIndex = tabIndex
            return true
        }
        return false
    }

    func display(provider: ASCFileProviderProtocol?, folder: ASCFolder?, inCategory categoryType: ASCFolderType? = nil) {
        guard let provider = provider else { return }

        if provider.type == .local {
            navigateLocalProvider(to: folder)
        } else if provider.type == .onlyoffice {
            navigateOnlyofficeProvider(to: folder, inCategory: categoryType)
        } else if provider.type == .icloud {
            navigateiCloudProvider(to: folder)
        } else {
            if selectTab(ofType: ASCCloudsSplitViewController.self) {
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
                if ASCEditorManager.shared.isOpenedFile,
                   let rootKeyWindowVC = UIWindow.keyWindow?.rootViewController
                {
                    UIAlertController.showWarning(
                        in: rootKeyWindowVC.topMostViewController(),
                        message: NSLocalizedString("Close the document before opening a new one.", comment: "")
                    )
                    return
                }

                var fileExt: String?

                if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewDocument) {
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.forceCreateNewDocument)
                    fileExt = ASCConstants.FileExtensions.docx
                } else if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewSpreadsheet) {
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.forceCreateNewSpreadsheet)
                    fileExt = ASCConstants.FileExtensions.xlsx
                } else if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewPresentation) {
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.forceCreateNewPresentation)
                    fileExt = ASCConstants.FileExtensions.pptx
                }

                guard let fileExtension = fileExt else {
                    return
                }

                if let rootVC = ASCViewControllerManager.shared.rootController {
                    rootVC.display(provider: ASCFileManager.localProvider, folder: nil)

                    delay(seconds: 0.3, completion: {
                        if let documentsVC = rootVC.topMostViewController() as? ASCDocumentsViewController,
                           let provider = documentsVC.provider
                        {
                            ASCCreateEntity().createFile(fileExtension, for: provider, in: documentsVC)
                        }
                    })
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

    @objc
    private func checkPushInfo() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let handlePushInfo: () -> Void = {
                if let userInfo = UserDefaults.standard.dictionary(forKey: ASCConstants.SettingsKeys.pushUserInfo) {
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.pushUserInfo)

                    if let stringUrl = userInfo["url"] as? String {
                        if let url = URL(string: stringUrl) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    } else if let navigationData = userInfo["data"] as? [String: Any] {
                        ASCViewControllerManager.shared.route(by: navigationData)
                    } else if let navigationDataString = userInfo["data"] as? String, let navigationData = navigationDataString.toDictionary() {
                        ASCViewControllerManager.shared.route(by: navigationData)
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

    func checkMDMConfigInfo() {
        ManagedAppConfig.shared.add(observer: self)
        ManagedAppConfig.shared.triggerHooks()
    }

    @objc
    private func networkStatusChanged() {
        if !ASCNetworkReachability.shared.isReachable {
            ASCBanner.shared.showError(
                title: NSLocalizedString("No network", comment: ""),
                message: NSLocalizedString("Check your internet connection", comment: "")
            )
        }
    }
}

// MARK: - UITabBarController Delegate

extension ASCRootViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
//        print("tabBarController didSelect")
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard tabBar.isUserInteractionEnabled else { return false }

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
                       let categoryVC = deviceSC.primaryViewController?.topMostViewController() as? ASCDeviceCategoryViewController
                    {
                        if isFirstOpenDeviceCategory { return true }
                        isFirstOpenDeviceCategory = true

                        categoryVC.select(category: categoryVC.deviceDocumentsCategory)
                    } else if let deviceSC = viewController as? ASCOnlyofficeSplitViewController,
                              let categoryVC = deviceSC.primaryViewController?.topMostViewController() as? ASCOnlyofficeCategoriesViewController
                    {
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
