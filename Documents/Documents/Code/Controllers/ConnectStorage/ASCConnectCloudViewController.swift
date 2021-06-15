//
//  ASCConnectCategoryViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 06/11/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import MBProgressHUD

class ASCConnectCloudViewController: UITableViewController {
    static let identifier = String(describing: ASCConnectCloudViewController.self)

    // MARK: - Properies

    var complation: ((ASCFileProviderProtocol) -> Void)?

    fileprivate let providerName: ((_ type: ASCFileProviderType) -> String) = { type in
        switch type {
        case .nextcloud:
            return NSLocalizedString("Nextcloud", comment: "")
        case .owncloud:
            return NSLocalizedString("ownCloud", comment: "")
        case .yandex:
            return NSLocalizedString("Yandex Disk", comment: "")
        case .webdav:
            return NSLocalizedString("WebDAV", comment: "")
        default:
            return NSLocalizedString("Unknown", comment: "")
        }
    }

    fileprivate let providerImage: ((_ type: ASCFileProviderType) -> UIImage?) = { type in
        switch type {
        case .nextcloud:
            return Asset.Images.logoNextcloudLarge.image
        case .owncloud:
            return Asset.Images.logoOwncloudLarge.image
        case .yandex:
            if Locale.preferredLanguages.first?.lowercased().contains("ru") ?? false {
                return Asset.Images.logoYandexdiskRuLarge.image
            } else {
                return Asset.Images.logoYandexdiskLarge.image
            }
        case .webdav:
            return Asset.Images.logoWebdavLarge.image
        default:
            return nil
        }
    }

    fileprivate let providerFolderType: ((_ type: ASCFileProviderType) -> ASCFolderType) = { type in
        switch type {
        case .nextcloud:
            return .nextcloudAll
        case .owncloud:
            return .owncloudAll
        case .yandex:
            return .yandexAll
        case .webdav:
            return .webdavAll
        default:
            return .unknown
        }
    }

    fileprivate let providerRootFolderTitle: ((_ type: ASCFileProviderType) -> String) = { type in
        switch type {
        case .nextcloud:
            return "Nextcloud"
        case .owncloud:
            return "ownCloud"
        case .yandex:
            return NSLocalizedString("Yandex Disk", comment: "")
        default:
            return NSLocalizedString("All Files", comment: "")
        }
    }

    fileprivate let providerRootFolderPath: ((_ type: ASCFileProviderType) -> String) = { type in
        switch type {
        case .nextcloud, .owncloud, .yandex, .webdav:
            return "/"
        default:
            return ""
        }
    }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return String.localizedStringWithFormat(
                NSLocalizedString("You can connect the following accounts to the %@.", comment: ""),
                ASCConstants.Name.appNameFull
            )
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            if let identifier = cell.reuseIdentifier {
                let providerType = ASCFileProviderType(rawValue: identifier) ?? .unknown
                
                switch providerType {
                case .googledrive:
                    tableView.deselectRow(at: indexPath, animated: true)
                    presentProviderConnection(by: providerType)
                case .dropbox:
                    presentProviderConnection(by: providerType, animated: true)
                default:
                    break
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Private

    private func authComplation(info: [String: Any]) {
        checkProvider(info: info) { [weak self] success, provider in
            if success, let provider = provider {
                let isNewProvider = (ASCFileManager.cloudProviders.first(where: { $0.id == provider.id }) == nil)

                if isNewProvider {
                    ASCFileManager.cloudProviders.insert(provider, at: 0)
                    ASCFileManager.storeProviders()
                }

                self?.complation?(provider)
                self?.dismiss(animated: true, completion: nil)
            } else {
                if let topViewController = UIApplication.topViewController() {
                    UIAlertController.showError(
                        in: topViewController,
                        message: (info["error"] as? String) ?? NSLocalizedString("Wrong login or password.", comment: "")
                    )
                }
            }
        }
    }

    private func checkProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void)) {
        guard let providerKey = info["providerKey"] as? String,
            let provider = ASCFolderProviderType(rawValue: providerKey)
        else {
            complation(false, nil)
            return
        }

        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

        switch provider {
        case .googleDrive:
            checkGoogleDriveProvider(info: info) { [weak self] success, provider in
                hud?.hide(animated: true)
                self?.tableView.reloadData()
                complation(success, provider)
            }
        case .dropBox:
            checkDropboxProvider(info: info) { [weak self] success, provider in
                hud?.hide(animated: true)
                self?.tableView.reloadData()
                complation(success, provider)
            }
        case .nextCloud:
            checkNextCloudProvider(info: info) { success, provider in
                hud?.hide(animated: true)
                complation(success, provider)
            }
        case .ownCloud:
            checkOwnCloudProvider(info: info) { success, provider in
                hud?.hide(animated: true)
                complation(success, provider)
            }
        case .yandex:
            checkYandexCloudProvider(info: info) { success, provider in
                hud?.hide(animated: true)
                complation(success, provider)
            }
        case .webDav:
            checkWebDavProvider(info: info) { success, provider in
                hud?.hide(animated: true)
                complation(success, provider)
            }
        default:
            hud?.hide(animated: false)
            complation(false, nil)
        }
    }

    private func checkGoogleDriveProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void)) {
        guard
            let user = info["user"] as? Data
        else {
            complation(false, nil)
            return
        }
        
        let googleDriveProvider = ASCGoogleDriveProvider(userData: user)

        googleDriveProvider.isReachable { success, error in
            DispatchQueue.main.async(execute: {
                complation(success, success ? googleDriveProvider : nil)
            })
        }
    }

    private func checkDropboxProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void)) {
        guard
            let token = info["token"] as? String
        else {
            complation(false, nil)
            return
        }
        
        let credential = URLCredential(user: ASCConstants.Clouds.Dropbox.clientId, password: token, persistence: .forSession)
        let dropboxCloudProvider = ASCDropboxProvider(credential: credential)
        
        dropboxCloudProvider.isReachable { success, error in
            DispatchQueue.main.async(execute: {
                complation(success, success ? dropboxCloudProvider : nil)
            })
        }
    }
    
    private func checkNextCloudProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void)) {
        guard
            let portal = info["url"] as? String,
            let login = info["login"] as? String,
            let password = info["password"] as? String,
            let portalUrl = URL(string: portal)
        else {
            complation(false, nil)
            return
        }

        let credential = URLCredential(user: login, password: password, persistence: .permanent)
        let nextCloudProvider = ASCNextCloudProvider(baseURL: portalUrl, credential: credential)

        nextCloudProvider.isReachable { success, error in
            DispatchQueue.main.async(execute: {
                complation(success, success ? nextCloudProvider : nil) // Need to capture nextCloudProvider variable
            })
        }
    }

    private func checkOwnCloudProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void)) {
        guard
            let portal = info["url"] as? String,
            let login = info["login"] as? String,
            let password = info["password"] as? String,
            let portalUrl = URL(string: portal)
            else {
                complation(false, nil)
                return
        }

        let credential = URLCredential(user: login, password: password, persistence: .permanent)
        let ownCloudProvider = ASCOwnCloudProvider(baseURL: portalUrl, credential: credential)

        ownCloudProvider.isReachable { success, error in
            DispatchQueue.main.async(execute: {
                complation(success, success ? ownCloudProvider : nil)
            })
        }
    }

    private func checkYandexCloudProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void)) {
        guard
            let login = info["login"] as? String,
            let password = info["password"] as? String
        else {
            complation(false, nil)
            return
        }

        let credential = URLCredential(user: login, password: password, persistence: .permanent)
        let yandexCloudProvider = ASCYandexFileProvider(credential: credential)
        let rootFolder: ASCFolder = {
            $0.title = NSLocalizedString("All Files", comment: "Category title")
            $0.rootFolderType = .yandexAll
            $0.id = providerRootFolderPath(yandexCloudProvider.type)
            return $0
        }(ASCFolder())

        yandexCloudProvider.fetch(for: rootFolder, parameters: [:]) { provider, folder, success, error in
            DispatchQueue.main.async(execute: {
                complation(success, success ? yandexCloudProvider : nil)
            })
        }
    }

    private func checkWebDavProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void)) {
        guard
            let portal = info["url"] as? String,
            let login = info["login"] as? String,
            let password = info["password"] as? String,
            let portalUrl = URL(string: portal)
            else {
                complation(false, nil)
                return
        }

//        let credential = URLCredential(user: login, password: password, persistence: .permanent)
//        let ownCloudProvider = ASCWebDAVProvider(baseURL: portalUrl, credential: credential)
//
//        ownCloudProvider.isReachable { success, error in
//            DispatchQueue.main.async(execute: {
//                complation(success, success ? ownCloudProvider : nil)
//            })
//        }

        let credential = URLCredential(user: login, password: password, persistence: .permanent)
        let webDavProvider = ASCWebDAVProvider(baseURL: portalUrl, credential: credential)
        let rootFolder: ASCFolder = {
            $0.title = NSLocalizedString("All Files", comment: "Category title")
            $0.rootFolderType = .webdavAll
            $0.id = providerRootFolderPath(webDavProvider.type)
            return $0
        }(ASCFolder())

        webDavProvider.fetch(for: rootFolder, parameters: [:]) { provider, folder, success, error in
            DispatchQueue.main.async(execute: {
                complation(success, success ? webDavProvider : nil)
            })
        }
    }

    func presentProviderConnection(by type: ASCFileProviderType, animated: Bool = false) {
        var connectionVC: UIViewController?

        switch type {
        case .googledrive:
            let googleConnectController = ASCConnectStorageGoogleController()
            googleConnectController.complation = { [weak self] info in
                self?.authComplation(info: info)
                let _ = googleConnectController
            }
            delay(seconds: 0.1) {
                googleConnectController.signIn(parentVC: self)
            }
            break
        case .dropbox:
            let oauth2VC = ASCConnectStorageOAuth2ViewController.instantiate(from: Storyboard.connectStorage)
            let dropboxController = ASCConnectStorageOAuth2Dropbox()
            dropboxController.clientId = ASCConstants.Clouds.Dropbox.clientId
            dropboxController.redirectUrl = ASCConstants.Clouds.Dropbox.redirectUri
            oauth2VC.responseType = .token
            oauth2VC.complation = authComplation(info:)
            oauth2VC.delegate = dropboxController
            oauth2VC.title = "Dropbox"
            
            if animated {
                navigationController?.pushViewController(oauth2VC, animated: animated)
            } else {
                connectionVC = oauth2VC
            }
        case .nextcloud:
            connectionVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(type)
                viewController.provider = .nextCloud
                viewController.logo = providerImage(type)
            }
        case .owncloud:
            connectionVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(type)
                viewController.provider = .ownCloud
                viewController.logo = providerImage(type)
            }
        case .yandex:
            connectionVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(type)
                viewController.provider = .yandex
                viewController.needServer = false
                viewController.logo = providerImage(type)
            }
        case .webdav:
            connectionVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(type)
                viewController.provider = .webDav
                viewController.logo = providerImage(type)
            }
        default:
            break
        }

        if let connectionVC = connectionVC {
            connectionVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) {
                connectionVC.navigationController?.dismiss(animated: true, completion: nil)
            }

            navigationController?.pushViewController(connectionVC, animated: animated)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
//        let connectStorageSegue = StoryboardSegue.ConnectStorage(rawValue: identifier)
        
        switch identifier {
        case "nextcloudSegue":
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(.nextcloud)
                viewController.provider = .nextCloud
                viewController.logo = providerImage(.nextcloud)
            }
        case "owncloudSegue":
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(.owncloud)
                viewController.provider = .ownCloud
                viewController.logo = providerImage(.owncloud)
            }
        case "webdavSegue":
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(.webdav)
                viewController.provider = .webDav
                viewController.logo = providerImage(.webdav)
            }
        case "yandexSegue":
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(.yandex)
                viewController.provider = .yandex
                viewController.logo = providerImage(.yandex)
            }
        default:
            break
        }
    }

}
