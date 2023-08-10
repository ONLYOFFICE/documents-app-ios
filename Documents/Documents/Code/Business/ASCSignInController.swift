//
//  ASCSignInController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17/05/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Firebase
import MBProgressHUD
import UIKit

typealias ASCSignInComplateHandler = (_ success: Bool) -> Void

class ASCSignInController {
    public static let shared = ASCSignInController()

    // MARK: - Properties

    weak var navigationController: UINavigationController?

    // MARK: - Private Methods

    private func presentSmsCodeViewController(request: OnlyofficeAuthRequest, completion: ASCSignInComplateHandler? = nil) {
        guard let navigationController = navigationController else {
            completion?(false)
            return
        }

        let smsCodeViewController = ASCSMSCodeViewController.instantiate(from: Storyboard.login)
        smsCodeViewController.request = request
        smsCodeViewController.completeon = completion
        navigationController.pushViewController(smsCodeViewController, animated: true)
    }

    private func presentPhoneNumberViewController(request: OnlyofficeAuthRequest, completion: ASCSignInComplateHandler? = nil) {
        guard let navigationController = navigationController else {
            completion?(false)
            return
        }

        let phoneViewController = ASCPhoneNumberViewController.instantiate(from: Storyboard.login)
        phoneViewController.request = request
        phoneViewController.completeon = completion
        navigationController.pushViewController(phoneViewController, animated: true)
    }

    private func presentTfaCodeViewController(request: OnlyofficeAuthRequest, completion: ASCSignInComplateHandler? = nil) {
        guard let navigationController = navigationController else {
            completion?(false)
            return
        }

        let tfaCodeVC = ASC2FACodeViewController.instantiate(from: Storyboard.login)
        tfaCodeVC.request = request
        tfaCodeVC.completeon = completion
        navigationController.pushViewController(tfaCodeVC, animated: true)
    }

    private func presentTfaSetupViewController(request: OnlyofficeAuthRequest, completion: ASCSignInComplateHandler? = nil) {
        guard let navigationController = navigationController else {
            completion?(false)
            return
        }

        let tfaSetupVC = ASC2FAViewController.instantiate(from: Storyboard.login)
        tfaSetupVC.request = request
        tfaSetupVC.completeon = completion
        navigationController.pushViewController(tfaSetupVC, animated: true)
    }

    // MARK: - Public

    func login(by request: OnlyofficeAuthRequest, completion: ASCSignInComplateHandler? = nil) {
        guard let portalUrl = request.portal?.lowercased() else {
            completion?(false)
            return
        }

        let api = OnlyofficeApiClient.shared

        var useProtocols: [String] = []

        if !portalUrl.matches(pattern: "^https?://") {
            useProtocols += ["https://", "http://"]
        }

        var tryLogin: (() -> Void)?

        tryLogin = {
            var baseUrl = portalUrl

            if let portalProtocol = useProtocols.first {
                baseUrl = portalProtocol + portalUrl
                useProtocols.removeFirst()
            }

            // Setup API manager
            api.baseURL = URL(string: baseUrl)

            let requestQueue = OperationQueue()
            requestQueue.maxConcurrentOperationCount = 1
            var lastError: Error?

            // Sign in
            requestQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                DispatchQueue.main.async {
                    OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Auth.authentication(with: request.code), request.toJSON()) { [weak self] response, error in
                        defer { semaphore.signal() }

                        lastError = error

                        if let auth = response?.result {
                            if let token = auth.token, !token.isEmpty {
                                // Set API token
                                api.token = token

                                // Set API access expires
                                let dateTransform = ASCDateTransform()
                                api.expires = dateTransform.transformFromJSON(auth.expires)
                            } else if auth.sms ?? false {
                                if let hud = MBProgressHUD.currentHUD {
                                    hud.hide(animated: false)
                                }

                                if let phoneNoise = auth.phoneNoise {
                                    request.phoneNoise = phoneNoise
                                    self?.presentSmsCodeViewController(request: request, completion: completion)
                                } else {
                                    self?.presentPhoneNumberViewController(request: request, completion: completion)
                                }
                            } else if auth.tfa ?? false {
                                if let hud = MBProgressHUD.currentHUD {
                                    hud.hide(animated: false)
                                }

                                if let tfaKey = auth.tfaKey {
                                    request.tfaKey = tfaKey
                                    self?.presentTfaSetupViewController(request: request, completion: completion)
                                } else {
                                    self?.presentTfaCodeViewController(request: request, completion: completion)
                                }
                            } else {
                                lastError = NetworkingError.apiError(error: OnlyofficeServerError(rawValue: "unauthorized"))
                            }
                        }
                    }
                }
                semaphore.wait()
            }

            // Get server version
            requestQueue.addOperation {
                if lastError == nil, let token = api.token {
                    let semaphore = DispatchSemaphore(value: 0)
                    DispatchQueue.main.async {
                        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Settings.versions) { response, error in
                            defer { semaphore.signal() }

                            if let error = error {
                                lastError = error
                                log.error(error)
                                return
                            }

                            if let versions = response?.result {
                                api.serverVersion = versions

                                // Init ONLYOFFICE provider
                                ASCFileManager.onlyofficeProvider = ASCOnlyofficeProvider(baseUrl: baseUrl, token: token)
                                ASCFileManager.provider = ASCFileManager.onlyofficeProvider
                                ASCFileManager.storeProviders()
                            }
                        }
                    }
                    semaphore.wait()
                }
            }

            // Fetch user info
            requestQueue.addOperation {
                if lastError == nil {
                    let semaphore = DispatchSemaphore(value: 0)
                    DispatchQueue.main.async {
                        if let onlyofficeProvider = ASCFileManager.onlyofficeProvider?.copy() as? ASCOnlyofficeProvider {
                            onlyofficeProvider.userInfo { success, error in
                                defer { semaphore.signal() }

                                if success {
                                    // Setup user info
                                    ASCFileManager.onlyofficeProvider?.user = onlyofficeProvider.user

                                    // Registration device into the portal
                                    OnlyofficeApiClient.request(
                                        OnlyofficeAPI.Endpoints.Auth.deviceRegistration,
                                        ["type": OnlyofficeApplicationType.documents.rawValue]
                                    )

                                    // Registration for push notification
                                    ASCPushNotificationManager.requestRegister()

                                    // Analytics
                                    if let portal = request.portal {
                                        ASCAnalytics.logEvent(ASCConstants.Analytics.Event.loginPortal, parameters: [
                                            ASCAnalytics.Event.Key.portal: portal,
                                            ASCAnalytics.Event.Key.provider: request.provider.rawValue,
                                        ])
                                    }

                                    // Fetch DocumentService information
                                    ASCEditorManager.shared.fetchDocumentService { _, _, _ in }

                                    completion?(true)
                                } else {
                                    lastError = NetworkingError.apiError(error: OnlyofficeServerError.unauthorized)

                                    if let error = error as? NetworkingError {
                                        switch error {
                                        case let .apiError(error):
                                            if let onlyofficeError = error as? OnlyofficeServerError {
                                                lastError = NetworkingError.apiError(error: onlyofficeError)
                                            }
                                        default:
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                    semaphore.wait()
                }
            }

            // Wait operations
            DispatchQueue.global(qos: .background).async {
                requestQueue.waitUntilAllOperationsAreFinished()

                // Done
                DispatchQueue.main.async {
                    if let hud = MBProgressHUD.currentHUD {
                        hud.hide(animated: false)
                    }

                    if let error = lastError {
                        log.error(error)
                    }

//                    if nil == api.token {
                    let defaultErrorMessage = String(format: NSLocalizedString("The %@ server is not available.", comment: ""), OnlyofficeApiClient.shared.baseURL?.absoluteString ?? "")

                    if lastError == nil, useProtocols.count > 0 {
                        if let topViewController = UIApplication.topViewController() {
                            let alertController = UIAlertController.alert(
                                ASCLocalization.Common.error,
                                message: String(format: "%@ %@", defaultErrorMessage, NSLocalizedString("Try to connect via another protocol?", comment: "")),
                                actions: []
                            )
                            .okable { _ in
                                tryLogin?()
                            }
                            .cancelable { _ in
                                completion?(false)
                            }

                            topViewController.present(alertController, animated: true, completion: nil)
                        } else {
                            completion?(false)
                        }
                    } else {
                        if let topViewController = UIApplication.topViewController() {
                            let alertController = UIAlertController.alert(
                                ASCLocalization.Common.error,
                                message: lastError?.localizedDescription ?? defaultErrorMessage,
                                actions: []
                            )
                            .okable { _ in
                                completion?(false)
                            }

                            topViewController.present(alertController, animated: true, completion: nil)
                        } else {
                            completion?(false)
                        }
                    }
                }
//                }
            }
        }

        tryLogin?()
    }

    func login(by request: OnlyofficeAuthRequest, in navigationController: UINavigationController?, completion: ASCSignInComplateHandler? = nil) {
        self.navigationController = navigationController
        login(by: request, completion: completion)
    }

    func presentSmsCode(in navigationController: UINavigationController, request: OnlyofficeAuthRequest, completion: ASCSignInComplateHandler?) {
        self.navigationController = navigationController
        presentSmsCodeViewController(request: request, completion: completion)
    }

    func presentPhoneNumber(in navigationController: UINavigationController, request: OnlyofficeAuthRequest, completion: ASCSignInComplateHandler?) {
        self.navigationController = navigationController
        presentPhoneNumberViewController(request: request, completion: completion)
    }
}
