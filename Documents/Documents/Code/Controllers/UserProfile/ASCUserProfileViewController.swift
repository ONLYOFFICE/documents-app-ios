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

class ASCUserProfileViewController: UITableViewController {

    // MARK: - Properties

    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var portalLabel: UILabel!
    @IBOutlet weak var emailTitleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var logoutCell: UITableViewCell!
    
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
        
        emailTitleLabel?.text = (ASCOnlyOfficeApi.shared.capabilities?.ldapEnabled ?? false)
            ? NSLocalizedString("Login", comment: "")
            : NSLocalizedString("Email", comment: "")
        
        if let user = ASCFileManager.onlyofficeProvider?.user {
            userNameLabel.text = user.displayName
            portalLabel.text = ASCOnlyOfficeApi.shared.baseUrl
            emailLabel.text = user.email
            
            if let avatar = user.avatarRetina ?? user.avatar,
                let avatarUrl = ASCOnlyOfficeApi.absoluteUrl(from: URL(string: avatar)) {
                avatarView.kf.apiSetImage(with: avatarUrl,
                                          placeholder: UIImage(named: "avatar-default"))
            } else {
                avatarView.image = UIImage(named: "avatar-default")
            }
        } else {
            userNameLabel.text = "-"
            portalLabel.text = "-"
            emailLabel.text = "-"
            avatarView.image = UIImage(named: "avatar-default")
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
    }

    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()

            var canvasFrame = canvasView.frame
            let bottomSafeAreaInset = view.safeAreaInsets.bottom

            canvasFrame.size.height = UIDevice.phone
                ? UIDevice.height - 280 - bottomSafeAreaInset
                : preferredContentSize.height - 190 - bottomSafeAreaInset
            canvasView.frame = canvasFrame
        }
    }
    
    static func logout(renewAccount: ASCAccount? = nil) {
        ASCOnlyOfficeApi.cancelAllTasks()

        // Cleanup auth info
        ASCOnlyOfficeApi.reset()

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
    
    @objc func updateUserUnfo(_ notification: Notification) {
        if let user = ASCFileManager.onlyofficeProvider?.user {
            userNameLabel?.text = user.displayName
            portalLabel?.text = ASCFileManager.onlyofficeProvider?.api.baseUrl
            emailLabel?.text = user.email

            if let avatar = user.avatarRetina ?? user.avatar,
                let avatarUrl = ASCOnlyOfficeApi.absoluteUrl(from: URL(string: avatar)) {
                avatarView?.kf.apiSetImage(with: avatarUrl,
                                           placeholder: UIImage(named: "avatar-default"))
            }
        }
    }
    
    // MARK: - Table view Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if cell == logoutCell {
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
    }
    
    // MARK: - Actions
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}
