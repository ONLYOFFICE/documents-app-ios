//
//  ASCConnectCategoryViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 06/11/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import SwiftyDropbox
import UIKit

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
        case .onedrive:
            return Asset.Images.logoOnedriveLarge.image
        case .kdrive:
            return Asset.Images.logoKdriveLarge.image
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
        case .onedrive:
            return .onedriveAll
        case .kdrive:
            return .kdriveAll
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
        case .onedrive:
            return "OneDrive"
        case .kdrive:
            return "kDrive"
        default:
            return NSLocalizedString("All Files", comment: "")
        }
    }

    fileprivate let providerRootFolderPath: ((_ type: ASCFileProviderType) -> String) = { type in
        switch type {
        case .nextcloud, .owncloud, .yandex, .webdav, .kdrive:
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
                case .onedrive:
                    presentProviderConnection(by: providerType, animated: true)
                default:
                    tableView.deselectRow(at: indexPath, animated: true)
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
        if let error = info["error"] as? String {
            UIAlertController.showError(
                in: self,
                message: error
            )
            return
        }

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
                        message: (info["error"] as? String) ?? NSLocalizedString("Wrong server, login or password.", comment: "")
                    )
                }
            }
        }
    }

    private func checkProvider(info: [String: Any], complation: @escaping ((_ success: Bool, _ provider: ASCFileProviderProtocol?) -> Void)) {
        guard let providerKey = info["providerKey"] as? String,
              let folderProviderType = ASCFolderProviderType(rawValue: providerKey)
        else {
            complation(false, nil)
            return
        }

        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

        if let provider = ASCFileManager.createProvider(by: folderProviderType) {
            provider.isReachable(with: info) { [weak self] success, provider in
                hud?.hide(animated: true)
                self?.tableView.reloadData()
                complation(success, provider)
            }
        } else {
            hud?.hide(animated: false)
            complation(false, nil)
        }
    }

    func presentProviderConnection(by type: ASCFileProviderType, animated: Bool = false) {
        var connectionVC: UIViewController?

        switch type {
        case .googledrive:
            let googleConnectController = ASCConnectStorageGoogleController()
            googleConnectController.complation = { [weak self] info in
                self?.authComplation(info: info)
                _ = googleConnectController
            }
            delay(seconds: 0.1) {
                googleConnectController.signIn(parentVC: self)
            }
        case .dropbox:
            if ASCConstants.Feature.dropboxSDKLogin {
                ASCDropboxSDKWrapper.shared.login(at: self) { [weak self] info in
                    self?.authComplation(info: info)
                }
            } else {
                let oauth2VC = ASCConnectStorageOAuth2ViewController.instantiate(from: Storyboard.connectStorage)
                let dropboxController = ASCConnectStorageOAuth2Dropbox()
                dropboxController.clientId = ASCConstants.Clouds.Dropbox.appId
                dropboxController.clientSecret = ASCConstants.Clouds.Dropbox.clientSecret
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
            }
        case .nextcloud:
            connectionVC = ASCConnectStorageNextCloudServerController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageNextCloudServerController {
                viewController.complation = authComplation(info:)
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
                viewController.logo = providerImage(type)
                viewController.needServer = false
            }
        case .webdav:
            connectionVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(type)
                viewController.provider = .webDav
                viewController.logo = providerImage(type)
            }
        case .onedrive:
            let oauth2VC = ASCConnectStorageOAuth2ViewController.instantiate(from: Storyboard.connectStorage)
            let onedriveController = ASCConnectStorageOAuth2OneDrive()
            onedriveController.clientId = ASCConstants.Clouds.OneDrive.clientId
            onedriveController.clientSecret = ASCConstants.Clouds.OneDrive.clientSecret
            onedriveController.redirectUrl = ASCConstants.Clouds.OneDrive.redirectUri
            onedriveController.authUrlVersion = .v2
            oauth2VC.responseType = .code
            oauth2VC.complation = authComplation(info:)
            oauth2VC.delegate = onedriveController
            oauth2VC.title = "OneDrive"

            if animated {
                navigationController?.pushViewController(oauth2VC, animated: animated)
            } else {
                connectionVC = oauth2VC
            }
        case .kdrive:
            connectionVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(type)
                viewController.provider = .kDrive
                viewController.logo = providerImage(type)
                viewController.needServer = false
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

        switch identifier {
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
                viewController.needServer = false
            }
        case "kdriveSegue":
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                viewController.complation = authComplation(info:)
                viewController.title = providerName(.kdrive)
                viewController.provider = .kDrive
                viewController.logo = providerImage(.kdrive)
                viewController.needServer = false
            }
        default:
            break
        }
    }
}
