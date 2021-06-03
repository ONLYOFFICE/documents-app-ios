//
//  ASCViewControllerManager.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/17/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import SwiftRater
import FileKit
import MBProgressHUD
import WhatsNewKit

class ASCViewControllerManager {
    public static let shared = ASCViewControllerManager()

    // MARK: - Properties

    var currentSizeClass: UIUserInterfaceSizeClass {
        get {
            if let rootController = rootController {
                return rootController.currentSizeClass
            }
            return .compact
        }
    }

    var rootController: ASCRootController? = nil {
        didSet {
            if oldValue == nil {
                initializeControllers()
            }
        }
    }

    var topViewController: UIViewController? {
        get {
            return rootController?.topMostViewController()
        }
    }

    var selectedViewController: UIViewController? {
        get {
            return rootController?.selectedViewController
        }
    }

    // MARK: - Lifecycle Methods

    private var openFileInfo: [String: Any]? {
        didSet {
            if let info = openFileInfo {
                routeOpenFile(info: info)
            }
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
        if  UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewDocument) ||
            UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewSpreadsheet) ||
            UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewPresentation)
        {
            rootController?.display(provider: ASCFileManager.localProvider, folder: nil)
        } else {
            var folder: ASCFolder? = nil

            if let folderAsString = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.lastFolder) {
                folder = ASCFolder(JSONString: folderAsString)
            }
            rootController?.display(provider: ASCFileManager.provider, folder: folder)
        }
        
        ASCEditorManager.shared.fetchDocumentService { _,_,_  in }
        
        // Check if first launch        
        let storeAppVersion = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.appVersion)
        
        if let appVersion = ASCCommon.appVersion, storeAppVersion != appVersion {
            UserDefaults.standard.set(appVersion, forKey: ASCConstants.SettingsKeys.appVersion)
            
            if storeAppVersion == nil {
                prepareContent()
                rootController?.display(provider: ASCFileManager.localProvider, folder: nil)
                showIntro()
            } else {
                showWhatsNew()
            }
        }

        configureRater()

        // Open file from outside
        if let info = openFileInfo {
            routeOpenFile(info: info)
            openFileInfo = nil
        }
    }

    func route(by url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
//        print("sourceApplication: \(options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String ?? "")")
//        print("annotation: \(options[UIApplicationOpenURLOptionsKey.annotation] as? String ?? "")")
        guard
            let url = URLComponents(string: url.absoluteString)
        else { return false }

        if "openfile" == url.host {
            if let data = url.queryItems?.first(where: { $0.name == "data" })?.value {
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
        }

        return false
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
    
    private func showIntro() {
        delay(seconds: 0.2) { [weak self] in
            if let topVC = self?.rootController?.topMostViewController() {
                let introController = ASCIntroViewController.instantiate(from: Storyboard.intro)
                introController.modalTransitionStyle = .crossDissolve

                if #available(iOS 13.0, *) {
                    introController.modalPresentationStyle = .fullScreen
                }

                topVC.present(introController, animated: true, completion: nil)
            }
        }
    }

    private func showWhatsNew() {
        // Initialize default Configuration
        var configuration = WhatsNewViewController.Configuration()
        configuration.completionButton.title = NSLocalizedString("Get started", comment: "")
        configuration.completionButton.backgroundColor = Asset.Colors.brend.color
        configuration.itemsView.titleFont = .systemFont(ofSize: 17, weight: .semibold)
        configuration.itemsView.subtitleFont = .systemFont(ofSize: 15)
        configuration.itemsView.autoTintImage = false
        
        if #available(iOS 13.0, *) {
            configuration.itemsView.subtitleColor = .secondaryLabel
        } else {
            configuration.itemsView.subtitleColor = .darkGray
        }

        /// Increase TitleView Insets
        configuration.titleView.insets.top = 60
        configuration.titleView.insets.bottom = 30
        
        /// Adjusts Insets for iPad
        configuration.padAdjustment = { configuration in
            /// Increase TitleView Insets
            configuration.titleView.insets.top = 80
            configuration.titleView.insets.left = 40
            configuration.titleView.insets.right = 40
            configuration.titleView.insets.bottom = 50
            
            /// Increase ItemsView Insets
            configuration.itemsView.insets.top = 10
            configuration.itemsView.insets.left = 80
            configuration.itemsView.insets.right = 80
            configuration.itemsView.insets.bottom = 20
            
            /// Increase CompletionButton Insets
            configuration.completionButton.insets.top = 40
            configuration.completionButton.insets.left = 80
            configuration.completionButton.insets.right = 80
            configuration.completionButton.insets.bottom = 40
        }
        
        // Initialize WhatsNew
        let whatsNew = WhatsNew(
            version: WhatsNew.Version(stringLiteral: ASCCommon.appVersion ?? "1.0"),
            title: NSLocalizedString("What's New", comment: ""),
            items: [
                WhatsNew.Item(
                    title: NSLocalizedString("iCloud Drive access", comment: ""),
                    subtitle: NSLocalizedString("View and edit files in iCloud directly from the app. Access your storage from the Clouds tab.", comment: ""),
                    image: Asset.Images.whatsnewFutureIcloudDrive.image
                ),
                WhatsNew.Item(
                    title: NSLocalizedString("Adding to Favorites", comment: ""),
                    subtitle: NSLocalizedString("Add files to Favorites for quick access directly from the editor.", comment: ""),
                    image: Asset.Images.whatsnewFutureFavourite.image
                ),
                WhatsNew.Item(
                    title: NSLocalizedString("Quick sharing", comment: ""),
                    subtitle: NSLocalizedString("Share files and manage access rights without leaving the editor.", comment: ""),
                    image: Asset.Images.whatsnewFutureShare.image
                )
            ]
        )

        let whatsNewViewController: WhatsNewViewController? = WhatsNewViewController(
            whatsNew: whatsNew,
            configuration: configuration
        )

        delay(seconds: 0.2) { [weak self] in
            if let topVC = self?.rootController?.topMostViewController() {
                if UIDevice.pad {
                    whatsNewViewController?.modalPresentationStyle = .formSheet
                    whatsNewViewController?.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
                }
                whatsNewViewController?.present(on: topVC)
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

    private func routeOpenFile(info: [String : Any]) {
        guard
            let portal = info["portal"] as? String,
            let email = info["email"] as? String,
            let fileJson = info["file"] as? [String: Any],
            let folderJson = info["folder"] as? [String: Any],
            var file = ASCFile(JSON: fileJson),
            var folder = ASCFolder(JSON: folderJson)
        else { return }

        /// Hide introdaction screen
        if let introViewController = ASCViewControllerManager.shared.rootController?.topMostViewController() as? ASCIntroViewController {
            introViewController.dismiss(animated: true, completion: nil)
        }

        let onlyofficeProvider = ASCFileManager.onlyofficeProvider
        
        if nil == onlyofficeProvider || portal != onlyofficeProvider?.api.baseUrl || email != onlyofficeProvider?.user?.email {
            openFileInfo = nil

            let account = ASCAccountsManager.shared.get(by: portal, email: email)
            let alertController = UIAlertController(
                title: NSLocalizedString("Open Document", comment:""),
                message: String(format: NSLocalizedString("To open a document, you must go to portal %@ under your account.", comment: ""), portal),
                preferredStyle: .alert,
                tintColor: nil
            )

            alertController.addAction(
                UIAlertAction(
                    title: (account != nil) ? NSLocalizedString("Switch", comment: "") : NSLocalizedString("Login", comment: ""),
                    style: .default,
                    handler: { action in//[weak self] action in
                        let currentAccout = ASCAccountsManager.shared.get(by: portal, email: email)
                        ASCUserProfileViewController.logout(renewAccount: currentAccout)
                    }
                )
            )

            alertController.addAction(
                UIAlertAction(
                    title: ASCLocalization.Common.cancel,
                    style: .cancel,
                    handler: nil
                )
            )

            ASCViewControllerManager.shared.rootController?.present(alertController, animated: true, completion: nil)

            return
        }

        if ASCEditorManager.shared.isOpenedFile, let topVC = ASCViewControllerManager.shared.rootController?.topMostViewController() {
            UIAlertController.showWarning(
                in: topVC,
                message: NSLocalizedString("To open a new document, you must exit the current document.", comment: "")
            )
            openFileInfo = nil
            return
        }

        let isRootFolder = folder.parentId == nil || folder.parentId == "0"

        let hud = MBProgressHUD.showTopMost()
        hud?.mode = .indeterminate
        hud?.label.text = NSLocalizedString("Opening", comment: "Caption of the processing")

        // Syncronize api calls
        let requestGroup = DispatchGroup()

        // Read full folder info
        if !isRootFolder {
            requestGroup.enter()
            ASCOnlyOfficeApi.get(String(format: ASCOnlyOfficeApi.apiFolderId, folder.id), completion: { result, error, response in
                if let result = result as? [String: Any],
                    let resultFolder = ASCFolder(JSON: result) {
                    folder = resultFolder
                } else {
                    folder.id = ""
                }
                requestGroup.leave()
            })
        }

        // Read full file info
        requestGroup.enter()
        ASCOnlyOfficeApi.get(String(format: ASCOnlyOfficeApi.apiFileId, file.id), completion: { result, error, response in
            if let result = result as? [String: Any],
                let resultFile = ASCFile(JSON: result) {
                file = resultFile
            } else {
                file.id = ""
            }
            requestGroup.leave()
        })

        DispatchQueue.global(qos: .background).async {
            requestGroup.wait()

            DispatchQueue.main.async {
                hud?.hide(animated: true)

                if file.id != "", folder.id != "" {
                    ASCViewControllerManager.shared.rootController?.display(provider: ASCFileManager.onlyofficeProvider, folder: folder)
                    
                    delay(seconds: 0.1) {
                        if let documentVC = ASCViewControllerManager.shared.rootController?.topMostViewController() as? ASCDocumentsViewController {
                            documentVC.open(file: file)
                        }
                    }
                } else if let topVC = ASCViewControllerManager.shared.rootController?.topMostViewController() {
                    UIAlertController.showError(
                        in: topVC,
                        message: NSLocalizedString("Failed to get information about the file.", comment: "")
                    )
                }
            }
        }
    }
}
