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

    var complation: ((ASCBaseFileProvider) -> Void)?

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

    fileprivate let providerImageName: ((_ type: ASCFileProviderType) -> String?) = { type in
        switch type {
        case .nextcloud:
            return "logo-nextcloud-large"
        case .owncloud:
            return "logo-owncloud-large"
        case .yandex:
            if Locale.preferredLanguages.first?.lowercased().contains("ru") ?? false {
                return "logo-yandexdisk-ru-large"
            } else {
                return "logo-yandexdisk-large"
            }
        case .webdav:
            return "logo-webdav-large"
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

    private func checkProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCBaseFileProvider?) -> Void)) {
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

    private func checkGoogleDriveProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCBaseFileProvider?) -> Void)) {
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

    private func checkDropboxProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCBaseFileProvider?) -> Void)) {
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
    
    private func checkNextCloudProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCBaseFileProvider?) -> Void)) {
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

    private func checkOwnCloudProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCBaseFileProvider?) -> Void)) {
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

    private func checkYandexCloudProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCBaseFileProvider?) -> Void)) {
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

    private func checkWebDavProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCBaseFileProvider?) -> Void)) {
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
                if let nameName = providerImageName(type) {
                    viewController.logo = UIImage(named: nameName)
                }
            }
        case .owncloud:
            connectionVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(type)
                viewController.provider = .ownCloud
                if let nameName = providerImageName(type) {
                    viewController.logo = UIImage(named: nameName)
                }
            }
        case .yandex:
            connectionVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(type)
                viewController.provider = .yandex
                viewController.needServer = false
                if let nameName = providerImageName(type) {
                    viewController.logo = UIImage(named: nameName)
                }
            }
        case .webdav:
            connectionVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(type)
                viewController.provider = .webDav
                if let nameName = providerImageName(type) {
                    viewController.logo = UIImage(named: nameName)
                }
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
        if segue.identifier == "dropboxSegue" {
            if let viewController = segue.destination as? ASCConnectStorageOAuth2ViewController {
                viewController.complation = authComplation(info:)
                let dropboxController = ASCConnectStorageOAuth2Dropbox()
                viewController.delegate = dropboxController
                viewController.title = "Dropbox"
            }
        } else if segue.identifier == "googleSegue" {
            if let viewController = segue.destination as? ASCConnectStorageOAuth2ViewController {
                viewController.complation = authComplation(info:)
                let googleController = ASCConnectStorageOAuth2Google()
                viewController.delegate = googleController
                viewController.title = "Google Drive"
            }
        } else if segue.identifier == "onedriveSegue" {
            if let viewController = segue.destination as? ASCConnectStorageOAuth2ViewController {
                viewController.complation = authComplation(info:)
                let onedriveController = ASCConnectStorageOAuth2OneDrive()
                viewController.delegate = onedriveController
                viewController.title = "OneDrive"
            }
        } else if segue.identifier == "boxSegue" {
            if let viewController = segue.destination as? ASCConnectStorageOAuth2ViewController {
                viewController.complation = authComplation(info:)
                let boxController = ASCConnectStorageOAuth2Box()
                viewController.delegate = boxController
                viewController.title = "Box"
            }
        } else if segue.identifier == "yandexSegue" {
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(.yandex)
                viewController.provider = .yandex
                viewController.needServer = false
                if let nameName = providerImageName(.yandex) {
                    viewController.logo = UIImage(named: nameName)
                }

            }
        } else if segue.identifier == "onedriveBusinessSegue" {
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = "OneDrive for Business"
                viewController.provider = .sharePoint
                viewController.logo = UIImage(named: "logo-onedrivepro-large")
            }
        } else if segue.identifier == "nextcloudSegue" {
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(.nextcloud)
                viewController.provider = .nextCloud
                if let nameName = providerImageName(.nextcloud) {
                    viewController.logo = UIImage(named: nameName)
                }
            }
        } else if segue.identifier == "owncloudSegue" {
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(.owncloud)
                viewController.provider = .ownCloud
                if let nameName = providerImageName(.owncloud) {
                    viewController.logo = UIImage(named: nameName)
                }
            }
        } else if segue.identifier == "sharepointSegue" {
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = "SharePoint"
                viewController.provider = .sharePoint
                viewController.logo = UIImage(named: "logo-sharepoint-large")
            }
        } else if segue.identifier == "webdavSegue" {
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(.webdav)
                viewController.provider = .webDav
                if let nameName = providerImageName(.webdav) {
                    viewController.logo = UIImage(named: nameName)
                }
            }
        }
    }

}
