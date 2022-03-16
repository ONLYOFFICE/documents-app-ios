//
//  ASCUserProfileViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/18/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import MBProgressHUD
import UIKit

class ASCUserProfileViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet var canvasView: UIView!
    @IBOutlet var avatarView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var portalLabel: UILabel!
    @IBOutlet var emailTitleLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var logoutCell: UITableViewCell!
    @IBOutlet var deleteAccountCell: UITableViewCell!

    let heightForHeaderInSection: CGFloat = 7
    let heightForFooterInSection: CGFloat = 7

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
               let avatarUrl = OnlyofficeApiClient.absoluteUrl(from: URL(string: avatar))
            {
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
            let cellHeight = deleteAccountCell.height + heightForFooterInSection + heightForHeaderInSection

            canvasFrame.size.height = UIDevice.phone
                ? UIDevice.height - navigationBarHeight - cellHeight * 3 - bottomSafeAreaInset
                : preferredContentSize.height - navigationBarHeight - cellHeight - bottomSafeAreaInset - 10
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
        OnlyofficeApiClient.reset()
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
               let avatarUrl = OnlyofficeApiClient.absoluteUrl(from: URL(string: avatar))
            {
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
        return heightForHeaderInSection
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return heightForFooterInSection
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
        guard let user = ASCFileManager.onlyofficeProvider?.user,
              let email = user.email else { return }

        let title = NSLocalizedString("Terminate account", comment: "")
        let message = String(format: NSLocalizedString("Send the profile deletion instructions to the email address %@?", comment: ""), email)
        let sendAlertAction = UIAlertAction(title: NSLocalizedString("Send", comment: ""),
                                            style: .default) { _ in
            let hud = MBProgressHUD.showTopMost()
            hud?.label.text = NSLocalizedString("Sending", comment: "")

            self.deleteAccountMailRequest { result in
                DispatchQueue.main.async {
                    hud?.hide(animated: true)
                    switch result {
                    case .success:
                        self.showSendAlert()
                    case let .failure(errorMessage):
                        print(errorMessage)
                        self.showErrorAlert(message: errorMessage)
                    }
                }
            }
        }

        let alertController = UIAlertController.alert(title, message: message, actions: [sendAlertAction])
            .cancelable()
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
            }
        )

        logoutController.addCancel()

        present(logoutController, animated: true, completion: nil)
    }

    private func deleteAccountMailRequest(completion: @escaping (RequestResult) -> Void) {
        OnlyofficeApiClient.shared.request(OnlyofficeAPI.Endpoints.Settings.deleteAccount) { response, error in
            guard error == nil else {
                completion(.failure(error!.localizedDescription))
                return
            }
            completion(.success)
        }
    }

    private func showSendAlert() {
        let alertController = UIAlertController.alert(
            NSLocalizedString("Instructions had been sent to your email", comment: ""),
            message: nil
        )
        present(alertController, animated: true, completion: nil)
    }

    private func showErrorAlert(message: String) {
        let alertController = UIAlertController.alert(NSLocalizedString("Error", comment: ""), message: message)
        present(alertController, animated: true, completion: nil)
    }
}

extension ASCUserProfileViewController {
    typealias ErrorMessage = String

    enum RequestResult {
        case success
        case failure(ErrorMessage)
    }
}
