//
//  ASCViewControllerManager.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/17/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import FileKit
import MBProgressHUD
import SwiftRater
import UIKit

class ASCViewControllerManager {
    public static let shared = ASCViewControllerManager()

    // MARK: - Properties

    var currentSizeClass: UIUserInterfaceSizeClass {
        if let rootController = rootController {
            return rootController.currentSizeClass
        }
        return .compact
    }

    var rootController: ASCRootViewController? {
        didSet {
            if oldValue == nil {
                initializeControllers()
            }
        }
    }

    var topViewController: UIViewController? {
        return rootController?.topMostViewController()
    }

    var selectedViewController: UIViewController? {
        return rootController?.selectedViewController
    }

    // MARK: - Lifecycle Methods

    private var openFileInfo: [String: Any]? {
        didSet {
            routeOpenFile()
        }
    }

    func initializeControllers() {
        ASCConstants.SettingsKeys.setupDefaults()
        ASCConstants.RemoteSettingsKeys.setupDefaults()

        // Setup global tintColor
        UIApplication.shared.delegate?.window??.tintColor = Asset.Colors.brend.color

        // Read stored providers
        ASCFileManager.loadProviders()

        // Open start category
        if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewDocument) ||
            UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewSpreadsheet) ||
            UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewPresentation)
        {
            rootController?.display(provider: ASCFileManager.localProvider, folder: nil)
        } else {
            var folder: ASCFolder?

            if let folderAsString = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.lastFolder) {
                folder = ASCFolder(JSONString: folderAsString)
            }
            rootController?.display(provider: ASCFileManager.provider, folder: folder)
        }

        ASCEditorManager.shared.fetchDocumentService { _, _, _ in }

        let appDelegate = UIApplication.shared.delegate as? AppDelegate

        if let _ = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.appVersion) {
            /// Display whats new if needed

            WhatsNewService.show()
            appDelegate?.checkNotifications()
        } else {
            /// Firsh launch of the app

            UserDefaults.standard.set(ASCCommon.appVersion, forKey: ASCConstants.SettingsKeys.appVersion)
            prepareContent()
            rootController?.display(provider: ASCFileManager.localProvider, folder: nil)
            showIntro {
                appDelegate?.checkNotifications()
            }
        }

        configureRater()

        /// Open file from outside
        routeOpenFile()
    }

    @discardableResult
    func route(by url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
//        print("sourceApplication: \(options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String ?? "")")
//        print("annotation: \(options[UIApplicationOpenURLOptionsKey.annotation] as? String ?? "")")
        guard
            let urlComponents = URLComponents(string: url.absoluteString)
        else { return false }

//        let path = url.path.replacingOccurrences(of: "://", with: "")

        if urlComponents.host == "openfile" {
            if let data = urlComponents.queryItems?.first(where: { $0.name == "data" })?.value {
                // Decode data
                if let urlDecode = Data(base64URLEncoded: data) {
                    do {
                        if let openInfo = try JSONSerialization.jsonObject(with: urlDecode, options: []) as? [String: Any] {
                            openFileInfo = openInfo
                            return true
                        }
                    } catch {
                        log.error(error.localizedDescription)
                    }
                }
            }
        } else if url.isFileURL {
            openFileInfo = ["url": url]
            return true
        }

        return false
    }

    @discardableResult
    func route(by json: [String: Any]) -> Bool {
        openFileInfo = json
        return true
    }

    // MARK: - Private

    private func configureRater() {
        SwiftRater.daysUntilPrompt = 1
        SwiftRater.usesUntilPrompt = 2
        SwiftRater.significantUsesUntilPrompt = 2
        SwiftRater.daysBeforeReminding = 2
        SwiftRater.showLaterButton = true
//        SwiftRater.debugMode = true
        SwiftRater.showLog = true
        SwiftRater.appLaunched()
    }

    private func showIntro(complation: (() -> Void)? = nil) {
        delay(seconds: 0.2) { [weak self] in
            if let topVC = self?.rootController?.topMostViewController() {
                let introController = ASCIntroViewController.instantiate(from: Storyboard.intro)
                introController.complation = complation
                introController.modalTransitionStyle = .crossDissolve

                if #available(iOS 13.0, *) {
                    introController.modalPresentationStyle = .fullScreen
                }

                topVC.present(introController, animated: true, completion: nil)
            }
        }
    }

    private func prepareContent() {
        let usersDocumentList = ASCLocalFileHelper.shared.entityList(Path.userDocuments)

        if usersDocumentList.count < 1, let resourcePath = Bundle.main.resourcePath {
            let sampleFolder = Path(resourcePath) + "sample"

            ASCLocalFileHelper.shared.copy(
                from: sampleFolder + "sample.docx",
                to: Path.userDocuments + String(
                    format: "%@.docx",
                    NSLocalizedString("Document Sample", comment: "Default title of sample document")
                )
            )
            ASCLocalFileHelper.shared.copy(
                from: sampleFolder + "sample.xlsx",
                to: Path.userDocuments + String(
                    format: "%@.xlsx",
                    NSLocalizedString("Spreadsheet Sample", comment: "Default title of sample document")
                )
            )
            ASCLocalFileHelper.shared.copy(
                from: sampleFolder + "sample.pptx",
                to: Path.userDocuments + String(
                    format: "%@.pptx",
                    NSLocalizedString("Presentation Sample", comment: "Default title of sample document")
                )
            )
        }
    }

    func routeOpenFile() {
        if let info = openFileInfo {
            if let url = info["url"] as? URL {
                if FileManager.default.isUbiquitousItem(at: url) {
                    // iCloud file
                    routeOpeniCloudFile(info: info)
                } else if url.absoluteString.contains(ASCFileManager.localProvider.rootFolder.id) {
                    if url.absoluteString.contains(ASCFileManager.localProvider.rootFolder.id.appendingPathComponent("Inbox")) {
                        // Import and open file
                        routeOpenLocalFile(info: info)
                    } else {
                        // Open file
                        routeOpenLocalFile(info: info, needImport: false)
                    }
                } else {
                    // Import and open file
                    routeOpenLocalFile(info: info)
                }
                openFileInfo = nil
            } else {
                // Portal
                routeOpenPortalEntity(info: info)
            }
        }
    }

    private func routeOpenLocalFile(info: [String: Any], needImport: Bool = true) {
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let url = info["url"] as? URL,
            url.isFileURL,
            !FileManager.default.isUbiquitousItem(at: url)
        else { return }

        let processAndOpenFile: () -> Void = { [weak self] in
            /// Reset open info
            self?.openFileInfo = nil

            /// Hide introdaction screen
            if let introViewController = ASCViewControllerManager.shared.rootController?.topMostViewController() as? ASCIntroViewController {
                introViewController.dismiss(animated: true, completion: nil)
            }

            /// Prevent open if open editor
            if ASCEditorManager.shared.isOpenedFile,
               let topWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
               let topVC = topWindow.rootViewController?.topMostViewController()
            {
                UIAlertController.showWarning(
                    in: topVC,
                    message: NSLocalizedString("To open a new document, you must exit the current document.", comment: "")
                )
                return
            }

            if needImport {
                /// Navigate and open
                ASCViewControllerManager.shared.rootController?.display(provider: ASCFileManager.localProvider, folder: nil)

                delay(seconds: 0.1) {
                    if let documentVC = ASCViewControllerManager.shared.rootController?.topMostViewController() as? ASCDocumentsViewController {
                        let successfulSecurityScopedResourceAccess = url.startAccessingSecurityScopedResource()

                        let fileTitle = url.lastPathComponent
                        let filePath = Path(url.path)

                        if let newFilePath = ASCLocalFileHelper.shared.resolve(filePath: Path.userDocuments + fileTitle)
                        {
                            if let error = ASCLocalFileHelper.shared.copy(from: filePath, to: newFilePath) {
                                log.error("Can not import the file. \(error)")
                            } else {
                                // Cleanup inbox
                                ASCLocalFileHelper.shared.removeDirectory(Path.userDocuments + "Inbox")

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
                                file.parent = documentVC.folder
                                file.displayContentLength = String.fileSizeToString(with: newFilePath.fileSize ?? 0)
                                file.pureContentLength = Int(newFilePath.fileSize ?? 0)

                                documentVC.add(entity: file, open: true)
                            }
                        }

                        if successfulSecurityScopedResourceAccess {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                }
            } else {
                guard
                    let url = URL(string: url.absoluteString.replacingOccurrences(of: "file:///private/var/", with: "file:///var/", options: .anchored)),
                    let path = Path(url: url)
                else { return }

                let owner = ASCUser()
                owner.displayName = UIDevice.displayName

                let folder = ASCFolder()
                folder.id = path.parent.rawValue
                folder.title = path.parent.fileName
                folder.parentId = Path.userDocuments.rawValue
                folder.device = true

                let file = ASCFile()
                file.id = path.rawValue
                file.rootFolderType = .deviceDocuments
                file.title = path.fileName
                file.created = path.creationDate
                file.updated = path.creationDate
                file.createdBy = owner
                file.updatedBy = owner
                file.parent = folder
                file.viewUrl = path.rawValue
                file.displayContentLength = String.fileSizeToString(with: path.fileSize ?? 0)
                file.pureContentLength = Int(path.fileSize ?? 0)
                file.device = true

                ASCViewControllerManager.shared.rootController?.display(provider: ASCFileManager.localProvider, folder: folder)

                delay(seconds: 0.1) {
                    if let documentVC = ASCViewControllerManager.shared.rootController?.topMostViewController() as? ASCDocumentsViewController {
                        documentVC.open(file: file)
                    }
                }
            }
        }

        if appDelegate.passcodeLockPresenter.isPasscodePresented {
            appDelegate.passcodeLockPresenter.passcodeLockVC.dismissCompletionCallback = {
                appDelegate.passcodeLockPresenter.dismissPasscodeLock()
                processAndOpenFile()
            }
        } else {
            processAndOpenFile()
        }
    }

    private func routeOpeniCloudFile(info: [String: Any]) {
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let url = info["url"] as? URL,
            url.isFileURL,
            FileManager.default.isUbiquitousItem(at: url)
        else { return }

        guard
            let iCloudProvider = ASCFileManager.cloudProviders.first(where: { $0 is ASCiCloudProvider }) as? ASCiCloudProvider,
            let relativePath = iCloudProvider.relativePathOf(url: url)
        else { return }

        let processAndOpenFile: () -> Void = { [weak self] in
            /// Reset open info
            self?.openFileInfo = nil

            /// Hide introdaction screen
            if let introViewController = ASCViewControllerManager.shared.rootController?.topMostViewController() as? ASCIntroViewController {
                introViewController.dismiss(animated: true, completion: nil)
            }

            /// Prevent open if open editor
            if ASCEditorManager.shared.isOpenedFile,
               let topWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
               let topVC = topWindow.rootViewController?.topMostViewController()
            {
                UIAlertController.showWarning(
                    in: topVC,
                    message: NSLocalizedString("To open a new document, you must exit the current document.", comment: "")
                )
                return
            }

            /// Navigate and open
            var folder = iCloudProvider.rootFolder

            if !relativePath.deletingLastPathComponent.isEmpty {
                folder = ASCFolder()
                folder.id = relativePath.deletingLastPathComponent
                folder.title = folder.id.lastPathComponent
            }

            let file = ASCFile()
            file.id = relativePath
            file.rootFolderType = .icloudAll
            file.title = relativePath.lastPathComponent
            file.createdBy = iCloudProvider.user
            file.updatedBy = iCloudProvider.user
            file.parent = folder
            file.viewUrl = relativePath

            ASCViewControllerManager.shared.rootController?.display(provider: iCloudProvider, folder: folder)

            delay(seconds: 0.1) {
                if let documentVC = ASCViewControllerManager.shared.rootController?.topMostViewController() as? ASCDocumentsViewController {
                    documentVC.open(file: file)
                }
            }
        }

        if appDelegate.passcodeLockPresenter.isPasscodePresented {
            appDelegate.passcodeLockPresenter.passcodeLockVC.dismissCompletionCallback = {
                appDelegate.passcodeLockPresenter.dismissPasscodeLock()
                processAndOpenFile()
            }
        } else {
            processAndOpenFile()
        }
    }

    /// Fix model under camelCase. Model for deeplink is wrong
    /// - Parameter dictionary: Dictionary with any key names
    /// - Returns: Dictionary with keys uses camelCase
    private func camelCaseKeys(of dictionary: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]

        for key in dictionary.keys {
            let correctKey = key.prefix(1).lowercased() + key.dropFirst()

            if let dictionary = dictionary[key] as? [String: Any] {
                result[correctKey] = camelCaseKeys(of: dictionary)
            } else {
                result[correctKey] = dictionary[key]
            }
        }

        return result
    }

    private func routeOpenPortalEntity(info: [String: Any]) {
        let correctInfo = camelCaseKeys(of: info)

        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let deepLink = ASCDeepLink(JSON: correctInfo),
            let originalUrl = deepLink.originalUrl,
            let portal = URL(string: originalUrl)?.dropPathAndQuery().absoluteString,
            let email = deepLink.email
        else { return }

        let rootSharedFolder = ASCFolder()
        rootSharedFolder.id = "@share"
        rootSharedFolder.rootFolderType = .onlyofficeShare

        var file = deepLink.file
        var folder = deepLink.folder ?? rootSharedFolder

        let isOpenFile = file != nil && !(file!.id.isEmpty)

        let processAndOpenFile: () -> Void = { [weak self] in
            /// Hide introdaction screen
            if let introViewController = ASCViewControllerManager.shared.rootController?.topMostViewController() as? ASCIntroViewController {
                introViewController.dismiss(animated: true, completion: nil)
            }

            let onlyofficeProvider = ASCFileManager.onlyofficeProvider

            if onlyofficeProvider == nil ||
                !(onlyofficeProvider?.apiClient.baseURL?.absoluteString ?? "").contains(portal) ||
                email != onlyofficeProvider?.user?.email
            {
                let account = ASCAccountsManager.shared.get(by: portal, email: email)
                let alertController = UIAlertController(
                    title: isOpenFile
                        ? NSLocalizedString("Open Document", comment: "")
                        : NSLocalizedString("Open Folder", comment: ""),
                    message: String(format: isOpenFile
                        ? NSLocalizedString("To open a document, you must go to portal %@ under your account.", comment: "")
                        : NSLocalizedString("To open a folder, you must go to portal %@ under your account.", comment: ""), portal),
                    preferredStyle: .alert,
                    tintColor: nil
                )

                alertController.addAction(
                    UIAlertAction(
                        title: (account != nil)
                            ? NSLocalizedString("Switch", comment: "")
                            : NSLocalizedString("Login", comment: ""),
                        style: .default,
                        handler: { action in

                            if let rootVC = ASCViewControllerManager.shared.rootController,
                               let onlyofficeSplitViewController = rootVC.viewControllers?.first(where: { $0 is ASCOnlyofficeSplitViewController }),
                               !onlyofficeSplitViewController.isViewLoaded
                            {
                                ASCViewControllerManager.shared.rootController?.display(
                                    provider: ASCOnlyofficeProvider(),
                                    folder: nil
                                )
                            } else {
                                ASCUserProfileViewController.logout(renewAccount: account)
                            }

                            if account == nil, ASCAccountsManager.shared.accounts.count > 0 {
                                delay(seconds: 0.3) {
                                    if let accountsVC = ASCViewControllerManager.shared.rootController?.topMostViewController() {
                                        accountsVC.navigationController?.pushViewController(ASCConnectPortalViewController.instance(), animated: true, completion: {})
                                    }
                                }
                            }
                        }
                    )
                )

                alertController.addAction(
                    UIAlertAction(
                        title: ASCLocalization.Common.cancel,
                        style: .cancel,
                        handler: { [weak self] action in
                            self?.openFileInfo = nil
                        }
                    )
                )

                delay(seconds: 1.0) {
                    ASCViewControllerManager
                        .shared
                        .rootController?
                        .topMostViewController()
                        .present(alertController, animated: true, completion: nil)
                }

                return
            }

            self?.openFileInfo = nil

            if ASCEditorManager.shared.isOpenedFile,
               let topWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
               let topVC = topWindow.rootViewController?.topMostViewController()
            {
                UIAlertController.showWarning(
                    in: topVC,
                    message: isOpenFile
                        ? NSLocalizedString("To open a new document, you must exit the current document.", comment: "")
                        : NSLocalizedString("To open a folder, you must exit the current document.", comment: "")
                )
                self?.openFileInfo = nil
                return
            }

            // Syncronize api calls
            let requestGroup = DispatchGroup()

            // Display hud
            let hud = MBProgressHUD.showTopMost()
            hud?.mode = .indeterminate
            hud?.label.text = NSLocalizedString("Opening", comment: "Caption of the processing")

            // Read full folder info
            requestGroup.enter()
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Folders.info(folder: folder)) { response, error in
                defer { requestGroup.leave() }

                if let resultFolder = response?.result {
                    folder = resultFolder
                } else {
                    folder = rootSharedFolder
                }
            }

            // Read full file info

            if let strongFile = file {
                requestGroup.enter()
                OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Files.info(file: strongFile)) { response, error in
                    defer { requestGroup.leave() }

                    if let resultFile = response?.result {
                        file = resultFile
                    } else {
                        file?.id = ""
                    }
                }
            }

            DispatchQueue.global(qos: .background).async {
                requestGroup.wait()

                DispatchQueue.main.async {
                    hud?.hide(animated: true)

                    if !folder.id.isEmpty {
                        delay(seconds: 0.2) {
                            if let copyFolder = ASCFolder(JSON: folder.toJSON()) {
                                // Correction root folfer type
                                if copyFolder.rootFolderType == .onlyofficeBunch {
                                    copyFolder.title = ASCOnlyofficeCategory.title(of: .onlyofficeProjects)
                                    copyFolder.rootFolderType = .onlyofficeProjects
                                }

                                if let topMostViewController = ASCViewControllerManager.shared.rootController?.topMostViewController() {
                                    let topOpenFolder: ASCFolder? = (topMostViewController as? ASCDocumentsViewController)?.folder

                                    if topOpenFolder != copyFolder {
                                        ASCViewControllerManager.shared.rootController?.display(
                                            provider: ASCFileManager.onlyofficeProvider,
                                            folder: copyFolder
                                        )
                                    }
                                }
                            }
                        }
                    }

                    if let file = file, !file.id.isEmpty {
                        delay(seconds: 0.3) {
                            if let topMostViewController = ASCViewControllerManager.shared.rootController?.topMostViewController(),
                               let documentVC = topMostViewController as? ASCDocumentsViewController
                            {
                                // Open target folder if not root folder
                                if !(documentVC.folder == folder), folder.parentId != nil {
                                    let controller = ASCDocumentsViewController.instantiate(from: Storyboard.main)
                                    documentVC.navigationController?.pushViewController(controller, animated: false)

                                    controller.provider = documentVC.provider?.copy()
                                    controller.folder = folder
                                    controller.title = folder.title

                                    controller.open(file: file)
                                } else {
                                    documentVC.open(file: file)
                                }
                            }
                        }
                    }
//                    } else if let topVC = ASCViewControllerManager.shared.rootController?.topMostViewController() {
//                        UIAlertController.showError(
//                            in: topVC,
//                            message: NSLocalizedString("Failed to get information about the file.", comment: "")
//                        )
//                    }
                }
            }
        }

        if appDelegate.passcodeLockPresenter.isPasscodePresented {
            appDelegate.passcodeLockPresenter.passcodeLockVC.dismissCompletionCallback = {
                appDelegate.passcodeLockPresenter.dismissPasscodeLock()
                processAndOpenFile()
            }
        } else {
            processAndOpenFile()
        }
    }
}
