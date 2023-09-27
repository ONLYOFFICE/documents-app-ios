//
//  ASCMultiAccountPresenter.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 03.04.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import Kingfisher
import MBProgressHUD

protocol ASCMultiAccountPresenterProtocol: AnyObject {
    var view: ASCMultiAccountViewProtocol? { get }
    func setup()
    func deleteFromDevice(account: ASCAccount?, completion: () -> Void)
    func renewal(by account: ASCAccount, animated: Bool)
}

class ASCMultiAccountPresenter: ASCMultiAccountPresenterProtocol {
    typealias TableData = ASCMultiAccountScreenModel.TableData

    // MARK: - Properties

    var view: ASCMultiAccountViewProtocol?

    // MARK: - Initialization

    init(view: ASCMultiAccountViewProtocol) {
        self.view = view
    }

    private lazy var deleteCallback: (ASCAccount) -> Void = { [weak self] account in
        guard let self = self else { return }
        self.view?.showDeleteAccountFromDeviceAlert(account: account)
    }

    // MARK: - Public methods

    func setup() {
        render()
    }

    func showProfile(viewController: ASCMultiAccountViewProtocol, account: ASCAccount?) {
        guard let account else { return }

        let userProfileVC = ASCUserProfileViewController.instantiate(from: Storyboard.userProfile)

        let userProfileNavigationVC = ASCBaseNavigationController(rootASCViewController: userProfileVC)
        userProfileNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
        userProfileNavigationVC.modalPresentationStyle = .formSheet

        let avatarUrl = absoluteUrl(from: URL(string: account.avatar ?? ""), for: account.portal ?? "")
        userProfileVC.viewModel = .init(userName: account.displayName ?? "-", email: account.email ?? "-", portal: account.portal ?? "-", avatarUrl: avatarUrl, userType: account.userType?.description ?? "") { [weak self] in
            guard let self = self else { return }
            self.login(by: account, completion: {})
        }

        viewController.navigationController?.pushViewController(userProfileVC, animated: true)
    }

    func deleteFromDevice(account: ASCAccount?, completion: () -> Void) {
        guard let account = account else { return }

        let currentAccount = ASCAccountsManager.shared.get(by: ASCFileManager.onlyofficeProvider?.apiClient.baseURL?.absoluteString ?? "", email: ASCFileManager.onlyofficeProvider?.user?.email ?? "")

        if account.email == currentAccount?.email, account.portal == currentAccount?.portal {
            logout()
        }
        ASCAccountsManager.shared.remove(account)
        render()
    }

    func renewal(by account: ASCAccount, animated: Bool = true) {
        let signinViewController = ASCSignInViewController.instantiate(from: Storyboard.login)
        signinViewController.renewal = true
        signinViewController.portal = account.portal
        signinViewController.email = account.email
        view?.navigationController?.pushViewController(signinViewController, animated: animated)
    }

    func login(by account: ASCAccount, completion: @escaping () -> Void) {
        OnlyofficeApiClient.shared.cancelAll()

        if let baseUrl = account.portal, let token = account.token {
            let dummyOnlyofficeProvider = ASCOnlyofficeProvider(baseUrl: baseUrl, token: token)

            let hud = MBProgressHUD.showTopMost()

            // Synchronize api calls
            let requestQueue = OperationQueue()
            requestQueue.maxConcurrentOperationCount = 1

            var lastErrorMsg: String?
            var allowPortal = false

            // Check portal if exist
            requestQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                self.checkPortalExist(baseUrl, completion: { success, errorMessage in
                    defer { semaphore.signal() }

                    allowPortal = success

                    if !success {
                        lastErrorMsg = errorMessage ?? NSLocalizedString("Failed to check portal availability.", comment: "")
                    }
                })
                semaphore.wait()
            }

            // Check portal version
            requestQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                self.checkServersVersion(baseUrl, completion: { success, errorMessage in
                    semaphore.signal()
                })
                semaphore.wait()
            }

            // Check read user info
            requestQueue.addOperation {
                if lastErrorMsg == nil {
                    let semaphore = DispatchSemaphore(value: 0)
                    ASCAccountsManager.shared.onUpdateUserInfoEnabled = false
                    dummyOnlyofficeProvider.userInfo { success, error in
                        ASCAccountsManager.shared.onUpdateUserInfoEnabled = true
                        if !success {
                            lastErrorMsg = error?.localizedDescription ?? NSLocalizedString("Failed to check portal availability.", comment: "")
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                }
            }

            DispatchQueue.global(qos: .background).async { [weak self] in
                requestQueue.waitUntilAllOperationsAreFinished()

                DispatchQueue.main.async { [weak self] in
                    guard let self = self
                    else {
                        OnlyofficeApiClient.reset()
                        hud?.hide(animated: true)
                        completion()
                        return
                    }

                    if !allowPortal {
                        hud?.hide(animated: false)

                        if let view = self.view, let errorMessage = lastErrorMsg {
                            UIAlertController.showError(
                                in: view,
                                message: NSLocalizedString("Portal is unavailable.", comment: "") + " " + errorMessage
                            )
                        }
                    } else if let _ = lastErrorMsg {
                        hud?.hide(animated: false)
                        self.renewal(by: account)
                    } else {
                        hud?.setSuccessState()

                        // Init ONLYOFFICE provider
                        ASCFileManager.onlyofficeProvider = ASCOnlyofficeProvider(baseUrl: baseUrl, token: token)
                        ASCFileManager.onlyofficeProvider?.user = dummyOnlyofficeProvider.user
                        ASCFileManager.provider = ASCFileManager.onlyofficeProvider
                        ASCFileManager.storeProviders()

                        // Notify
                        NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)

                        // Registration device into the portal
                        OnlyofficeApiClient.request(
                            OnlyofficeAPI.Endpoints.Auth.deviceRegistration,
                            ["type": OnlyofficeApplicationType.documents.rawValue]
                        )

                        // Registration for push notification
                        ASCPushNotificationManager.requestRegister()

                        ASCAnalytics.logEvent(ASCConstants.Analytics.Event.switchAccount, parameters: [
                            ASCAnalytics.Event.Key.portal: baseUrl,
                        ])

                        ASCEditorManager.shared.fetchDocumentService { _, _, _ in }

                        self.view?.dismiss(animated: true, completion: nil)

                        hud?.hide(animated: true, afterDelay: 0.3)
                    }

                    completion()
                }
            }
        }
    }

    // MARK: - Private methods

    private func absoluteUrl(from url: URL?, for portal: String) -> URL? {
        if let url = url {
            if let _ = url.host {
                return url
            } else {
                return URL(string: portal + url.absoluteString)
            }
        }
        return nil
    }

    private func checkPortalExist(_ portal: String, completion: @escaping (Bool, String?) -> Void) {
        OnlyofficeApiClient.shared.baseURL = URL(string: portal)
        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Settings.capabilities) { response, error in
            if let error = error {
                log.error(error)
                OnlyofficeApiClient.shared.baseURL = nil
                completion(false, error.localizedDescription)
            } else if let capabilities = response?.result {
                OnlyofficeApiClient.shared.capabilities = capabilities
                completion(true, nil)
            } else {
                OnlyofficeApiClient.shared.baseURL = nil
                completion(false, NSLocalizedString("Failed to check portal availability.", comment: ""))
            }
        }
    }

    private func checkServersVersion(_ portal: String, completion: @escaping (Bool, String?) -> Void) {
        OnlyofficeApiClient.shared.baseURL = URL(string: portal)
        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Settings.versions) { response, error in
            if let error = error {
                log.error(error)
            }

            if let versions = response?.result {
                OnlyofficeApiClient.shared.serverVersion = versions
            }

            completion(true, nil)
        }
    }

    private func logout() {
        ASCUserProfileViewController.logout()
    }

    private func buildMultiAccountScreenModel() -> ASCMultiAccountScreenModel {
        let tableData: TableData = .init(sections: [.simple(getAddAccountCellModels() + getAccountCellModels())])
        let title = NSLocalizedString("Accounts", comment: "")
        return ASCMultiAccountScreenModel(title: title, tableData: tableData)
    }

    private func getAddAccountCellModels() -> [TableData.Cell] {
        let text = NSLocalizedString("Add account", comment: "")
        return [AddAccountCellModel(image: "",
                                    text: text)].map { model in
            .addAccount(model)
        }
    }

    private func isActiveUser(account: ASCAccount) -> Bool {
        guard let onlyOfficeProvider = ASCFileManager.onlyofficeProvider,
              let authorizedUserPortal = onlyOfficeProvider.apiClient.baseURL?.absoluteString,
              let authorizedUser = onlyOfficeProvider.user
        else {
            return false
        }

        return account.portal == authorizedUserPortal && account.email == authorizedUser.email
    }

    private func getAccountCellModels() -> [TableData.Cell] {
        return ASCAccountsManager.shared.accounts.map { account in
            let portal = removeScheme(from: account.portal ?? "")
            return AccountCellModel(avatarUrl: account.avatarAbsoluteUrl,
                                    name: account.displayName ?? "",
                                    portal: portal ?? "",
                                    isActiveUser: isActiveUser(account: account),
                                    showProfileCallback: { [weak self] in
                                        guard let self = self, let view = self.view else { return }
                                        self.showProfile(viewController: view, account: account)
                                    },
                                    selectCallback: { [weak self] in
                                        guard let self = self else { return }
                                        self.login(by: account, completion: {})
                                    },
                                    deleteCallback: { [weak self] in
                                        guard let self = self else { return }
                                        self.deleteCallback(account)
                                    })
        }.map { model in
            .account(model)
        }
    }

    private func removeScheme(from urlString: String) -> String? {
        guard !urlString.isEmpty,
              var url = URLComponents(string: urlString) else { return nil }
        url.scheme = nil
        let cleanedUrlString = url.string?.replacingOccurrences(of: "//", with: "")
        return cleanedUrlString
    }

    private func render() {
        view?.desplayData(data: buildMultiAccountScreenModel())
    }
}
