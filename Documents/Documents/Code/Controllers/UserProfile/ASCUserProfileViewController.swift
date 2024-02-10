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
    enum Constants {
        static var sectionInsets: CGFloat = 7
    }

    struct ViewModel {
        let userName: String
        let email: String
        let portal: String
        let avatarUrl: URL?
        let userType: String

        var onLogin: () -> Void

        static let empty = ViewModel(userName: "-", email: "-", portal: "-", avatarUrl: nil, userType: "-", onLogin: {})
    }

    // MARK: - Properties

    @IBOutlet var canvasView: UIView!
    @IBOutlet var avatarView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var portalLabel: UILabel!
    @IBOutlet var emailTitleLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var logoutCell: UITableViewCell!
    @IBOutlet var deleteAccountCell: UITableViewCell!
    @IBOutlet var profileTypeTitleLabel: UILabel!
    @IBOutlet var profileTypeLabel: UILabel!
    @IBOutlet var logoutCellLabel: UILabel!

    let heightForHeaderInSection: CGFloat = Constants.sectionInsets
    let heightForFooterInSection: CGFloat = Constants.sectionInsets

    lazy var viewModel: ViewModel = .empty

    private var isUserTypeExists: Bool {
        viewModel.userType == "" || viewModel.userType == "-" ? false : true
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        profileTypeLabel.isHidden = !isUserTypeExists
        profileTypeTitleLabel.isHidden = !isUserTypeExists

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

        userNameLabel.text = viewModel.userName
        portalLabel.text = viewModel.portal
        emailLabel.text = viewModel.email
        profileTypeLabel.text = viewModel.userType
        avatarView.kf.apiSetImage(with: viewModel.avatarUrl, placeholder: Asset.Images.avatarDefault.image)
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

        if !isCurrentUser() {
            logoutCellLabel.text = NSLocalizedString("Sign in", comment: "")
            logoutCellLabel.textColor = view.tintColor
        }

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

        // Unsubscribe from push notifications
        ASCPushNotificationManager.requestClearRegister()

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

        NotificationCenter.default.post(
            name: ASCConstants.Notifications.logoutOnlyofficeCompleted,
            object: nil,
            userInfo: userInfo
        )
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
            if !isCurrentUser() {
                viewModel.onLogin()
            } else {
                showLogoutAlert()
            }
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
            hud.hide(animated: true, afterDelay: .twoSecondsDelay)
        }

        guard let navigationController = navigationController else {
            if let presentingViewController = presentingViewController as? UINavigationController,
               let splitVC = splitViewController as? ASCBaseSplitViewController
            {
                presentingViewController.dismiss(animated: true) {
                    if #available(iOS 14.0, *) {
                        splitVC.show(.primary)
                    } else {
                        let primaryVC = ASCMultiAccountsViewController()
                        var viewControllers = splitVC.viewControllers
                        viewControllers.insert(primaryVC, at: 0)
                        splitVC.viewControllers = viewControllers
                    }
                }
            }
            return
        }
        navigationController.popToRootViewController(animated: true)
    }

    private func isCurrentUser() -> Bool {
        guard
            let portal = ASCFileManager.onlyofficeProvider?.apiClient.baseURL?.absoluteString,
            let user = ASCFileManager.onlyofficeProvider?.user,
            user.email == viewModel.email,
            portal == viewModel.portal
        else { return false }
        return true
    }

    private func showDeleteAccountAlert() {
        guard let user = ASCFileManager.onlyofficeProvider?.user else { return }

        if user.isOwner {
            showDeleteAccountOwnerAlert()
        } else {
            showDeleteAccountUserAlert()
        }
    }

    private func showDeleteAccountUserAlert() {
        guard
            let user = ASCFileManager.onlyofficeProvider?.user,
            let email = user.email
        else { return }

        let title = NSLocalizedString("Terminate account", comment: "")
        let message = String(format: NSLocalizedString("Send the profile deletion instructions to the email address %@?", comment: ""), email)

        showAlert(
            title: title,
            message: message,
            buttonTitles: [
                NSLocalizedString("Send", comment: ""),
                ASCLocalization.Common.cancel,
            ],
            highlightedButtonIndex: 0,
            completion: { index in
                if index == 0 {
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
            }
        )
    }

    private func showDeleteAccountOwnerAlert() {
        let protalType = ASCPortalTypeDefinderByCurrentConnection().definePortalType()

        let title = NSLocalizedString("Terminate account", comment: "")
        let message = protalType == .docSpace
            ? NSLocalizedString("Being an owner of this DocSpace, you must transfer the ownership to another user before you can delete your account. Please choose a new owner to proceed.", comment: "")
            : NSLocalizedString("Being an owner of this portal, you must transfer the ownership to another user before you can delete your account. Please choose a new owner to proceed.", comment: "")

        showAlert(
            title: title,
            message: message,
            buttonTitles: [
                NSLocalizedString("Change owner", comment: ""),
                ASCLocalization.Common.cancel,
            ],
            highlightedButtonIndex: 0,
            completion: { index in
                if index == 0 {
                    if let url = OnlyofficeApiClient.shared.baseURL,
                       UIApplication.shared.canOpenURL(url)
                    {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
        )
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
