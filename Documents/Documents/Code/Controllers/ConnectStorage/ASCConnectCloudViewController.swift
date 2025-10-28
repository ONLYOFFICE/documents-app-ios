//
//  ASCConnectCloudViewController.swift
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

    private var connectCloudProviders: [ASCFileProviderType] {
        var correctDefaultConnectCloudProviders = ASCConstants.Clouds.defaultConnectCloudProviders
        let allowGoogleDrive = ASCConstants.remoteConfigValue(forKey: ASCConstants.RemoteSettingsKeys.allowGoogleDrive)?.boolValue ?? true

        if !allowGoogleDrive {
            correctDefaultConnectCloudProviders.removeAll(.googledrive)
        }
        return correctDefaultConnectCloudProviders
    }

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
        case .googledrive:
            return Asset.Images.logoGoogledriveLarge.image
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
            return .default
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
        view.tintColor = Asset.Colors.brend.color
        super.viewDidLoad()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        connectCloudProviders.count
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = ASCConnectStorageCell.createForTableView(tableView) as? ASCConnectStorageCell else { return UITableViewCell() }

        cell.type = {
            switch connectCloudProviders[indexPath.row] {
            case .webdav:
                return .webDav
            case .nextcloud:
                return .nextCloud
            case .owncloud:
                return .ownCloud
            case .yandex:
                return .yandex
            case .dropbox:
                return .dropBox
            case .googledrive:
                return .googleDrive
            case .onedrive:
                return .oneDrive
            case .kdrive:
                return .kDrive
            default:
                return .others
            }
        }()
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 78
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ASCConnectStorageCell {
            if let type = cell.type {
                switch type {
                case .nextCloud:
                    presentProviderConnection(by: .nextcloud, animated: true)
                case .ownCloud:
                    presentProviderConnection(by: .owncloud, animated: true)
                case .googleDrive:
                    tableView.deselectRow(at: indexPath, animated: true)
                    presentProviderConnection(by: .googledrive)
                case .dropBox:
                    presentProviderConnection(by: .dropbox, animated: true)
                case .oneDrive:
                    presentProviderConnection(by: .onedrive, animated: true)
                case .kDrive:
                    presentProviderConnection(by: .kdrive, animated: true)
                case .webDav:
                    presentProviderConnection(by: .webdav, animated: true)
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

                guard let self else {
                    return
                }

                if isNewProvider {
                    ASCFileManager.cloudProviders.insert(provider, at: 0)
                    ASCFileManager.storeProviders()
                }

                complation?(provider)
                dismiss(animated: true, completion: nil)
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
            if ASCAppSettings.Feature.dropboxSDKLogin {
                ASCDropboxSDKWrapper.shared.login(at: self) { info in
                    self.authComplation(info: info)
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
            let viewController = ASCConnectStorageNextCloudServerController.instantiate(from: Storyboard.connectStorage)
            viewController.complation = authComplation(info:)
            if animated {
                navigationController?.pushViewController(viewController, animated: animated)
            } else {
                connectionVC = viewController
            }
        case .owncloud:
            let viewController = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            viewController.configuration = ASCConnectStorageWebDavControllerConfiguration(
                provider: .ownCloud,
                logo: providerImage(type),
                title: providerName(type),
                complation: authComplation(info:)
            )
            if animated {
                navigationController?.pushViewController(viewController, animated: animated)
            } else {
                connectionVC = viewController
            }
        case .yandex:
            connectionVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            if let viewController = connectionVC as? ASCConnectStorageWebDavController {
                viewController.configuration = ASCConnectStorageWebDavControllerConfiguration(
                    provider: .yandex,
                    needServer: false,
                    logo: providerImage(type),
                    title: providerName(type),
                    instruction: NSLocalizedString("<p>Use the password created in <a href=\"https://yandex.ru/id/about\">Yandex ID</a>.</p><p>More detailed connection instructions can be found in the <a href=\"https://yandex.ru/support/disk-desktop/webdav-app-passwords.html?lang=ru\">help</a>.</p>", comment: ""),
                    complation: authComplation(info:)
                )
            }
        case .webdav:
            let viewController = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            viewController.configuration = ASCConnectStorageWebDavControllerConfiguration(
                provider: .webDav,
                logo: providerImage(type),
                title: providerName(type),
                complation: authComplation(info:)
            )
            if animated {
                navigationController?.pushViewController(viewController, animated: animated)
            } else {
                connectionVC = viewController
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
            let viewController = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            viewController.configuration = ASCConnectStorageWebDavControllerConfiguration(
                provider: .kDrive,
                loginTitle: NSLocalizedString("Email", comment: ""),
                needServer: false,
                logo: providerImage(type),
                title: providerName(type),
                instruction: NSLocalizedString("<p>You must have a paid version of the player to use this service.</p><p>If you have activated double authentication, please generate a CDM application from the Infomaniak manager. <a href=\"https://www.infomaniak.com/en/support/faq/1940/enable-two-step-verification\">More...</a></p>", comment: ""),
                complation: authComplation(info:)
            )
            if animated {
                navigationController?.pushViewController(viewController, animated: animated)
            } else {
                connectionVC = viewController
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
                var configuration = ASCConnectStorageWebDavControllerConfiguration.defaultConfiguration()
                configuration.complation = authComplation(info:)
                configuration.title = providerName(.owncloud)
                configuration.provider = .ownCloud
                configuration.logo = providerImage(.owncloud)
                viewController.configuration = configuration
            }
        case "webdavSegue":
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                var configuration = ASCConnectStorageWebDavControllerConfiguration.defaultConfiguration()
                configuration.complation = authComplation(info:)
                configuration.title = providerName(.webdav)
                configuration.provider = .webDav
                configuration.logo = providerImage(.webdav)
                viewController.configuration = configuration
            }
        case "yandexSegue":
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                var configuration = ASCConnectStorageWebDavControllerConfiguration.defaultConfiguration()
                configuration.complation = authComplation(info:)
                configuration.title = providerName(.yandex)
                configuration.provider = .yandex
                configuration.logo = providerImage(.yandex)
                configuration.needServer = false
                configuration.instruction = NSLocalizedString("<p>Use the password created in <a href=\"https://yandex.ru/id/about\">Yandex ID</a>.</br>More detailed connection instructions can be found in the <a href=\"https://yandex.ru/support/disk-desktop/webdav-app-passwords.html?lang=ru\">help</a>.</p>", comment: "")
                viewController.configuration = configuration
            }
        case "kdriveSegue":
            if let viewController = segue.destination as? ASCConnectStorageWebDavController {
                var configuration = ASCConnectStorageWebDavControllerConfiguration.defaultConfiguration()
                configuration.complation = authComplation(info:)
                configuration.title = providerName(.kdrive)
                configuration.provider = .kDrive
                configuration.logo = providerImage(.kdrive)
                configuration.needServer = false
                configuration.instruction = NSLocalizedString("<p>You must have a paid version of the player to use this service.</p><p>If you have activated double authentication, please generate a CDM application from the Infomaniak manager. <a href=\"https://www.infomaniak.com/en/support/faq/1940/enable-two-step-verification\">More...</a></p>", comment: "")
                viewController.configuration = configuration
            }
        default:
            break
        }
    }
}
