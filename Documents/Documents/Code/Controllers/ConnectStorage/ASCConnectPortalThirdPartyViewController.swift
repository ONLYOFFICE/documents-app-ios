//
//  ASCConnectStorageViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/16/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import MBProgressHUD

class ASCConnectPortalThirdPartyViewController: UITableViewController {

    // MARK: - Properies
    
    static private let maxTitle = 170

    private var providers: [(provider: ASCFolderProviderType, info: [String: String])] = []
    private var defaultProviders: [ASCFolderProviderType] = ASCConstants.Clouds.defaultConnectFolderProviders

    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }

        fetchProviders()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Private

    private func fetchProviders() {
        providers = []

        tableView.reloadData()
        tableView.isUserInteractionEnabled = false

        let activity = UIActivityIndicatorView(style: .gray)
        activity.startAnimating()
        tableView.addSubview(activity)
        activity.anchorCenterSuperview()

        ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiThirdPartyCapabilities) { [weak self] (result, error, response) in
            guard let strongSelf = self else { return }

            activity.removeFromSuperview()
            strongSelf.tableView.isUserInteractionEnabled = true

            var localProviders: [(provider: ASCFolderProviderType, info: [String: String])] = []

            if let providersInfo = result as? [[String]], providersInfo.count > 0 {
                for providerInfo in providersInfo {
                    if let type = ASCFolderProviderType(rawValue: providerInfo.first ?? "") {
                        var info: [String: String] = [:]

                        for (index, item) in providerInfo.enumerated() {
                            if index == 1 {
                                info["clientId"] = item
                            } else if index == 2 {
                                info["redirectUrl"] = item
                            }
                        }

                        localProviders.append((provider: type, info: info))
                    }
                }
            }

            strongSelf.defaultProviders.forEach { type in
                if let defaultProviderIndex = localProviders.firstIndex(where: { $0.provider == type }) {
                    localProviders.remove(at: defaultProviderIndex)
                }
                localProviders.append(((provider: type, info: [:])))
            }

            /// Override the list according to preference.
            var orderedProviders: [(provider: ASCFolderProviderType, info: [String: String])] = []
           
            ASCConstants.Clouds.preferredOrderCloudProviders.forEach { type in
                if let providerInfo = localProviders.first(where: { $0.provider == type }) {
                    orderedProviders.append(providerInfo)
                }
            }
            
            strongSelf.providers = orderedProviders
            strongSelf.tableView.reloadData()

        }
    }
    
    private func authComplation(info: [String: Any]) {
        var folderName = NSLocalizedString("Cloud directory", comment: "Default external storage name")
        
        if  let providerKey = info["providerKey"] as? String,
            let type = ASCFolderProviderType(rawValue: providerKey)
        {
            switch type {
            case .googleDrive:
                folderName = NSLocalizedString("Google directory", comment: "")
                break
            case .dropBox:
                folderName = NSLocalizedString("Dropbox directory", comment: "")
                break
            case .skyDrive,
                 .oneDrive:
                folderName = NSLocalizedString("OneDrive directory", comment: "")
                break
            case .boxNet:
                folderName = NSLocalizedString("Box directory", comment: "")
                break
            case .sharePoint:
                folderName = NSLocalizedString("SharePoint directory", comment: "")
                break
            case .yandex:
                folderName = NSLocalizedString("Yandex directory", comment: "")
                break
            case .webDav:
                folderName = NSLocalizedString("WebDAV directory", comment: "")
                break
            default:
                break
            }
        }
        
        dismiss(animated: true) { 
            let alertController = UIAlertController(
                title: NSLocalizedString("Folder title", comment: ""),
                message: nil,
                preferredStyle: .alert,
                tintColor: nil
            )
            let cancelAction = UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .cancel,
                handler:
            { action in
                if let textField = alertController.textFields?.first {
                    textField.selectedTextRange = nil
                }
            })
            let connectAction = UIAlertAction(
                title: NSLocalizedString("Connect", comment: "Button title"),
                style: .default,
                handler:
            { action in
                guard let textField = alertController.textFields?.first else {
                    return
                }
                
                textField.selectedTextRange = nil
                
                if var folderTitle = textField.text?.trim() {
                    if folderTitle.length < 1 {
                        folderTitle = folderName
                    }
                    
                    var params = info
                    params["customerTitle"] = folderTitle
                    
                    self.connectFolder(params)
                }
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(connectAction)
            alertController.addTextField { (textField) in
                textField.delegate = self
                textField.text = folderName
                
                textField.add(for: .editingChanged, {
                    connectAction.isEnabled = (textField.text?.trim().length)! > 0
                })
                
                delay(seconds: 0.2) {
                    textField.selectAll(nil)
                }
            }

            if let topVC = ASCViewControllerManager.shared.topViewController {
                topVC.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    private func connectFolder(_ params: [String: Any]) {
        guard let rootVC = ASCViewControllerManager.shared.rootController else {
            return
        }
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Creating", comment: "Caption of the process")
        
        ASCOnlyOfficeApi.post(ASCOnlyOfficeApi.apiThirdParty, parameters: params) { (result, error, response) in
            if error != nil {
                hud?.hide(animated: true)
                UIAlertController.showError(
                    in: rootVC.topMostViewController(),
                    message: ASCOnlyOfficeApi.errorMessage(by: response!)
                )
                log.error(error!)
            } else {
                if let folderInfo = result as? [String: Any] {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: 1.3)
                    
                    if  let splitVC = ASCViewControllerManager.shared.topViewController as? ASCOnlyofficeSplitViewController,
                        let documentsVC = (splitVC.detailViewController ?? splitVC.primaryViewController)?.topMostViewController() as? ASCDocumentsViewController,
                        let newFolder = ASCFolder(JSON: folderInfo),
                        let categoryFolder = documentsVC.folder,
                        categoryFolder.rootFolderType == .onlyofficeUser,
                        (categoryFolder.parentId == nil || categoryFolder.parentId == "0") // is onlyoffice root of user's folder
                    {
                        documentsVC.add(entity: newFolder)
                    } else {
                        rootVC.display(
                            provider: ASCFileManager.onlyofficeProvider,
                            folder: ASCOnlyofficeCategory.folder(of: .onlyofficeUser)
                        )

                        delay(seconds: 0.3) {
                            if  let splitVC = ASCViewControllerManager.shared.topViewController as? ASCOnlyofficeSplitViewController,
                                let documentsVC = (splitVC.detailViewController ?? splitVC.primaryViewController)?.topMostViewController() as? ASCDocumentsViewController
                            {
                                documentsVC.highlight(entity: ASCFolder(JSON: folderInfo))
                            }
                        }
                    }
                } else {
                    hud?.hide(animated: true)
                    UIAlertController.showError(
                        in: rootVC.topMostViewController(),
                        message: ASCOnlyOfficeApi.errorMessage(by: response!)
                    )
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation

    private func presentViewController(by providerType: ASCFolderProviderType) {
        var viewController: UIViewController?
        let providerInfo: [String: String] = providers.first(where: { $0.provider == providerType })?.info ?? [:]

        switch providerType {

        case .dropBox:
            let oauth2VC = ASCConnectStorageOAuth2ViewController.instantiate(from: Storyboard.connectStorage)
            let dropboxController = ASCConnectStorageOAuth2Dropbox()
            dropboxController.clientId = providerInfo["clientId"]
            dropboxController.redirectUrl = providerInfo["redirectUrl"]
            oauth2VC.complation = authComplation(info:)
            oauth2VC.delegate = dropboxController
            oauth2VC.title = "Dropbox"
            viewController = oauth2VC

        case .google, .googleDrive:
            let oauth2VC = ASCConnectStorageOAuth2ViewController.instantiate(from: Storyboard.connectStorage)
            let googleController = ASCConnectStorageOAuth2Google()
            googleController.clientId = providerInfo["clientId"]
            googleController.redirectUrl = providerInfo["redirectUrl"]
            oauth2VC.complation = authComplation(info:)
            oauth2VC.delegate = googleController
            oauth2VC.title = NSLocalizedString("Google Drive", comment: "")
            viewController = oauth2VC

        case .skyDrive, .oneDrive:
            let oauth2VC = ASCConnectStorageOAuth2ViewController.instantiate(from: Storyboard.connectStorage)
            let onedriveController = ASCConnectStorageOAuth2OneDrive()
            onedriveController.clientId = providerInfo["clientId"]
            onedriveController.redirectUrl = providerInfo["redirectUrl"]
            oauth2VC.complation = authComplation(info:)
            oauth2VC.delegate = onedriveController
            oauth2VC.title = "OneDrive"
            viewController = oauth2VC

        case .boxNet:
            let oauth2VC = ASCConnectStorageOAuth2ViewController.instantiate(from: Storyboard.connectStorage)
            let boxController = ASCConnectStorageOAuth2Box()
            boxController.clientId = providerInfo["clientId"]
            boxController.redirectUrl = providerInfo["redirectUrl"]
            oauth2VC.complation = authComplation(info:)
            oauth2VC.delegate = boxController
            oauth2VC.title = "Box"
            viewController = oauth2VC

        case .yandex:
            let webDavVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            webDavVC.complation = authComplation(info:)
            webDavVC.title = NSLocalizedString("Yandex Disk", comment: "")
            webDavVC.provider = .yandex
            webDavVC.logo = (Locale.preferredLanguages.first?.lowercased().contains("ru") ?? false)
                ? UIImage(named: "logo-yandexdisk-ru-large")
                : UIImage(named: "logo-yandexdisk-large")
            webDavVC.needServer = false
            viewController = webDavVC

        case .sharePoint:
            let webDavVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            webDavVC.complation = authComplation(info:)
            webDavVC.title = NSLocalizedString("OneDrive for Business", comment: "")
            webDavVC.provider = .sharePoint
            webDavVC.logo = UIImage(named: "logo-onedrivepro-large")
            viewController = webDavVC

        case .nextCloud:
            let webDavVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            webDavVC.complation = authComplation(info:)
            webDavVC.title = "Nextcloud"
            webDavVC.provider = .webDav
            webDavVC.logo = UIImage(named: "logo-nextcloud-large")
            viewController = webDavVC

        case .ownCloud:
            let webDavVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            webDavVC.complation = authComplation(info:)
            webDavVC.title = "ownCloud"
            webDavVC.provider = .webDav
            webDavVC.logo = UIImage(named: "logo-owncloud-large")
            viewController = webDavVC

        case .webDav:
            let webDavVC = ASCConnectStorageWebDavController.instantiate(from: Storyboard.connectStorage)
            webDavVC.complation = authComplation(info:)
            webDavVC.title = "WebDAV"
            webDavVC.provider = .webDav
            webDavVC.logo = UIImage(named: "logo-webdav-large")
            viewController = webDavVC
        }

        if let viewController = viewController {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

// MARK: - UITableView Delegate

extension ASCConnectPortalThirdPartyViewController {

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0, providers.count > 0 {
            return String.localizedStringWithFormat(NSLocalizedString("You can connect the following accounts to the %@. They will be displayed in 'My Documents' folder and you will be able to edit and save them right on the portal all in one place.", comment: ""), ASCConstants.Name.appNameFull)
        }
        return nil
    }

}


// MARK: - UITableView DataSource

extension ASCConnectPortalThirdPartyViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return providers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ASCConnectStorageCell.identifier, for: indexPath) as? ASCConnectStorageCell {
            cell.type = providers[indexPath.row].provider
            return cell
        }
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presentViewController(by: providers[indexPath.row].provider)
    }

}

// MARK: - UITextField Delegate

extension ASCConnectPortalThirdPartyViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.isFirstResponder {
            if let primaryLanguage = textField.textInputMode?.primaryLanguage, primaryLanguage == "emoji" {
                return false
            }
        }
        
        if let nsString = textField.text as NSString? {
            var newString = nsString.replacingCharacters(in: range, with: string)
            let newStringLenght = newString.length
            
            if newStringLenght < 1 {
                return true
            }
            
            newString = newString.trimmingCharacters(in: CharacterSet(charactersIn: String.invalidTitleChars))
            
            if newStringLenght != newString.length {
                return false
            }
            
            return newString.length < ASCConnectPortalThirdPartyViewController.maxTitle
        }
        
        return false
    }

}
