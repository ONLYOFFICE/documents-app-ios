//
//  ASCUserProfileViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/18/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import Kingfisher
import MBProgressHUD
import WebKit

class ASCUserProfileViewController: UITableViewController {

    // MARK: - Properties

    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var portalLabel: UILabel!
    @IBOutlet weak var emailTitleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var logoutCell: UITableViewCell!
    @IBOutlet weak var deleteAccountCell: UITableViewCell!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUserUnfo(_:)),
            name: ASCConstants.Notifications.userInfoOnlyofficeUpdate,
            object: nil
        )
        
        avatarView.kf.indicatorType = .activity

        if UIDevice.pad {
            preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
        }
        
        var canvasFrame = canvasView.frame
        canvasFrame.size.height = UIDevice.phone
            ? UIDevice.height - 300
            : preferredContentSize.height
        canvasView.frame = canvasFrame
        
        emailTitleLabel?.text = (OnlyofficeApiClient.shared.capabilities?.ldapEnabled ?? false)
            ? NSLocalizedString("Login", comment: "")
            : NSLocalizedString("Email", comment: "")
        
        if let user = ASCFileManager.onlyofficeProvider?.user {
            userNameLabel.text = user.displayName
            portalLabel.text = OnlyofficeApiClient.shared.baseURL?.absoluteString
            emailLabel.text = user.email
            
            if let avatar = user.avatarRetina ?? user.avatar,
                let avatarUrl = OnlyofficeApiClient.absoluteUrl(from: URL(string: avatar)) {
                avatarView.kf.apiSetImage(with: avatarUrl,
                                          placeholder: Asset.Images.avatarDefault.image)
            } else {
                avatarView.image = Asset.Images.avatarDefault.image
            }
        } else {
            userNameLabel.text = "-"
            portalLabel.text = "-"
            emailLabel.text = "-"
            avatarView.image = Asset.Images.avatarDefault.image
        }
    }
    
    deinit {
         NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.navigationBar.prefersLargeTitles = false
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        tableView.alwaysBounceVertical = false
    }

    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()

            var canvasFrame = canvasView.frame
            let bottomSafeAreaInset = view.safeAreaInsets.bottom
            let navigationBarHeight = (navigationController?.navigationBar.y ?? 0) + (navigationController?.navigationBar.height ?? 0)

            canvasFrame.size.height = UIDevice.phone
                ? UIDevice.height - navigationBarHeight - 225 - bottomSafeAreaInset
                : preferredContentSize.height - navigationBarHeight - bottomSafeAreaInset
            canvasView.frame = canvasFrame
        }
    }
    
    static func logout(renewAccount: ASCAccount? = nil) {
        OnlyofficeApiClient.shared.cancelAll()

        // Cleanup auth info
        OnlyofficeApiClient.reset()

        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.collaborationService)

        // Cleanup ONLYOFFICE provider
        ASCFileManager.onlyofficeProvider?.reset()
        ASCFileManager.onlyofficeProvider = nil
        ASCFileManager.storeProviders()

        var userInfo: [String: Any]?

        if let account = renewAccount {
            userInfo = ["account": account]
        }

        NotificationCenter.default.post(name: ASCConstants.Notifications.logoutOnlyofficeCompleted,
                                        object: nil,
                                        userInfo: userInfo)
    }

    @objc func updateUserUnfo(_ notification: Notification) {
        if let user = ASCFileManager.onlyofficeProvider?.user {
            userNameLabel?.text = user.displayName
            portalLabel?.text = ASCFileManager.onlyofficeProvider?.apiClient.baseURL?.absoluteString
            emailLabel?.text = user.email

            if let avatar = user.avatarRetina ?? user.avatar,
                let avatarUrl = OnlyofficeApiClient.absoluteUrl(from: URL(string: avatar)) {
                avatarView?.kf.apiSetImage(with: avatarUrl,
                                           placeholder: Asset.Images.avatarDefault.image)
            }
        }
    }
    
    // MARK: - Table view Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if cell == logoutCell {
            showLogoutAlert()
        } else if cell == deleteAccountCell {
            showDeleteAccountAlert()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 7
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 7
    }
        
    // MARK: - Actions
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Private
    
    private func onLogout() {
        ASCUserProfileViewController.logout()
        
        if let hud = MBProgressHUD.showTopMost() {
            hud.setSuccessState(title: NSLocalizedString("Logout", comment: "Caption of the process"))
            hud.hide(animated: true, afterDelay: 2)
        }
        
        dismiss(animated: true) {
//            if let parent = self.presentingViewController {
//                parent.viewWillAppear(false)
//            }
        }
    }
    
    private func showDeleteAccountAlert() {
        let titleAlert = NSLocalizedString("Terminate account", comment: "")
        let messageAlert = NSLocalizedString("You have requested a termination of account sample@gmail.com. After the deletion, your account and all data associated with it will be erased permanently in accordance with our Privacy statement.", comment: "")
        
        let alertController = UIAlertController(title: titleAlert,
                                                message: messageAlert,
                                                preferredStyle: .alert)
        let cancelAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                              style: .cancel)
        let deleteAlertAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""),
                                              style: .default) { _ in
            guard let user = ASCFileManager.onlyofficeProvider?.user else { return }
            if user.isAdmin {
                self.showDeletingOwnerPortalAlert()
            } else  {
                self.showConfirmationTerminateAlert()
            }
        }
        
        alertController.addAction(cancelAlertAction)
        alertController.addAction(deleteAlertAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func showLogoutAlert() {
        let logoutController = UIAlertController(
            title: NSLocalizedString("Are you sure you want to leave this account?", comment: ""),
            message: nil,
            preferredStyle: UIDevice.phone ? .actionSheet : .alert,
            tintColor: nil
        )
        
        logoutController.addAction(
            title: NSLocalizedString("Logout", comment: "Button title"),
            style: .destructive,
            handler: { action in
            self.onLogout()
        })
        
        logoutController.addCancel()
        
        present(logoutController, animated: true, completion: nil)
    }
    
    private func showConfirmationTerminateAlert(){
        let terminateAccountController = UIAlertController(
            title: NSLocalizedString("Terminate account",comment: ""),
            message: NSLocalizedString("Enter password to complete data termintaion.", comment: ""),
            preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: NSLocalizedString("Confirm termination", comment: ""),
                                          style: .default)
        let cancelAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                              style: .cancel)
        terminateAccountController.addAction(confirmAction)
        terminateAccountController.addAction(cancelAlertAction)
        terminateAccountController.addTextField { textField in
            textField.isSecureTextEntry = true
        }
        present(terminateAccountController, animated: true, completion: nil)
    }
    
    private func showDeletingOwnerPortalAlert() {
        let terminateAccountController = UIAlertController(
            title: NSLocalizedString("Terminate account",comment: ""),
            message: NSLocalizedString("You want to terminate account sample@gmail.com. This account is owner of portal sample.onlyoffice.eu, so it cannot be deleted without removing all portal data. To complete account termation, you need to change owner in portal access settings first or delete entire portal.", comment: ""),
            preferredStyle: .alert)
        let openPortalAction = UIAlertAction(title: NSLocalizedString("Open portal settings", comment: ""),
                                             style: .default) { _ in
            self.openWebView()
        }
        
        let cancelAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                              style: .cancel)
        terminateAccountController.addAction(openPortalAction)
        terminateAccountController.addAction(cancelAlertAction)
 
        present(terminateAccountController, animated: true, completion: nil)
    }
    
    private func openWebView() {
        guard var portalUrl = portalLabel.text else { return }
        portalUrl = portalUrl.appendingPathComponent(ASCConstants.Urls.portalUserAccessRightsPath)
        
        let webViewController = ASCWebKitViewController(urlString: portalUrl)
        let nc = UINavigationController(rootASCViewController: webViewController)
        nc.modalPresentationStyle = .fullScreen
        
        navigationController?.present(nc, animated: true, completion: nil)
    }
}
