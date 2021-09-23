//
//  ASCSignInController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17/05/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD
import Firebase

typealias ASCSignInComplateHandler = (_ success: Bool) -> Void

class ASCSignInController {
    public static let shared = ASCSignInController()

    // MARK: - Properties

    weak var navigationController: UINavigationController?

    // MARK: - Private Methods

    private func presentSmsCodeViewController(options: Parameters, completion: ASCSignInComplateHandler? = nil) {
        guard let navigationController = navigationController else {
            completion?(false)
            return
        }

        let smsCodeViewController = ASCSMSCodeViewController.instantiate(from: Storyboard.login)
        smsCodeViewController.options = options
        smsCodeViewController.completeon = completion
        navigationController.pushViewController(smsCodeViewController, animated: true)
    }

    private func presentPhoneNumberViewController(options: Parameters, completion: ASCSignInComplateHandler? = nil) {
        guard let navigationController = navigationController else {
            completion?(false)
            return
        }

        let phoneViewController = ASCPhoneNumberViewController.instantiate(from: Storyboard.login)
        phoneViewController.options = options
        phoneViewController.completeon = completion
        navigationController.pushViewController(phoneViewController, animated: true)
    }

    private func presentTfaCodeViewController(options: Parameters, completion: ASCSignInComplateHandler? = nil) {
        guard let navigationController = navigationController else {
            completion?(false)
            return
        }

        let tfaCodeVC = ASC2FACodeViewController.instantiate(from: Storyboard.login)
        tfaCodeVC.options = options
        tfaCodeVC.completeon = completion
        navigationController.pushViewController(tfaCodeVC, animated: true)
    }

    private func presentTfaSetupViewController(options: Parameters, completion: ASCSignInComplateHandler? = nil) {
        guard let navigationController = navigationController else {
            completion?(false)
            return
        }

        let tfaSetupVC = ASC2FAViewController.instantiate(from: Storyboard.login)
        tfaSetupVC.options = options
        tfaSetupVC.completeon = completion
        navigationController.pushViewController(tfaSetupVC, animated: true)
    }

    // MARK: - Public

    func login(by type: ASCLoginType, options: Parameters, completion: ASCSignInComplateHandler? = nil) {
        guard var portalUrl = options["portal"] as? String else {
            completion?(false)
            return
        }

        let api             = ASCOnlyOfficeApi.shared
        let email           = options["userName"] as? String
        let password        = options["password"] as? String
        let facebookToken   = options["facebookToken"] as? String
        let googleToken     = options["googleToken"] as? String
        let accessToken     = options["accessToken"] as? String

        var apiRequest      = ASCOnlyOfficeApi.apiAuthentication
        var apiOptions: [String: Any] = [:]

        portalUrl = portalUrl.lowercased()

        if type == .facebook {
            apiOptions["provider"] = type
            apiOptions["accessToken"] = facebookToken ?? accessToken
        } else if type == .google {
            apiOptions["provider"]  = type
            apiOptions["accessToken"] = googleToken ?? accessToken
        } else {
            apiOptions["provider"] = type
            apiOptions["userName"] = email
            apiOptions["password"] = password
        }

        apiOptions["portal"] = portalUrl

        if let code = options["code"] as? String {
            apiRequest = apiRequest + "/" + code
            apiOptions["code"] = code
        }

        var useProtocols = [String]()

        if !portalUrl.matches(pattern: "^https?://") {
            useProtocols += ["https://", "http://"]
        }

        func internalLogin() {
            var baseUrl = portalUrl

            if let portalProtocol = useProtocols.first {
                baseUrl = portalProtocol + portalUrl
                useProtocols.removeFirst()
            }

            // Setup API manager
            api.baseUrl = baseUrl

            ASCOnlyOfficeApi.post(apiRequest, parameters: apiOptions) { [weak self] (results, error, response) in
                if let results = results as? [String: Any] {
                    if let token = results["token"] as? String, token != "" {
                        // Set API token
                        api.token = token

                        // Set API access expires
                        let dateTransform = ASCDateTransform()
                        api.expires = dateTransform.transformFromJSON(results["expires"])

                        // Get server version
                        ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiServersVersion) { results, error, response in
                            if let versions = results as? [String: Any] {
                                if let communityServer = versions["communityServer"] as? String {
                                    ASCOnlyOfficeApi.shared.serverVersion = communityServer
                                }
                            }

                            // Init ONLYOFFICE provider
                            ASCFileManager.onlyofficeProvider = ASCOnlyofficeProvider(baseUrl: baseUrl, token: token)
                            ASCFileManager.provider = ASCFileManager.onlyofficeProvider
                            ASCFileManager.storeProviders()

                            // Fetch user info
                            if let onlyofficeProvider = ASCFileManager.onlyofficeProvider?.copy() as? ASCOnlyofficeProvider {
                                onlyofficeProvider.userInfo { success, error in
                                    if success {
                                        ASCFileManager.onlyofficeProvider?.user = onlyofficeProvider.user
                                        
                                        completion?(true)

                                        // Registration device into the portal
                                        ASCOnlyOfficeApi.post(ASCOnlyOfficeApi.apiDeviceRegistration, parameters: ["type": 2], completion: { (_, _, _) in
                                            // 2 - IOSDocuments
                                        })

                                        if let portal = apiOptions["portal"], let provider = apiOptions["provider"] as? ASCLoginType {
                                            ASCAnalytics.logEvent(ASCConstants.Analytics.Event.loginPortal, parameters: [
                                                ASCAnalytics.Event.Key.portal: portal,
                                                ASCAnalytics.Event.Key.provider: provider.rawValue
                                                ]
                                            )
                                        }

                                        ASCEditorManager.shared.fetchDocumentService { _,_,_  in }
                                    } else {
                                        completion?(false)
                                    }
                                }
                            }
                        }
                    } else if results["sms"] as? Bool ?? false {
                        if let hud = MBProgressHUD.currentHUD {
                            hud.hide(animated: false)
                        }

                        if let phoneNoise = results["phoneNoise"] as? String {
                            apiOptions["phoneNoise"] = phoneNoise
                            self?.presentSmsCodeViewController(options: apiOptions, completion: completion)
                        } else {
                            self?.presentPhoneNumberViewController(options: apiOptions, completion: completion)
                        }
                    } else if results["tfa"] as? Bool ?? false {
                        if let hud = MBProgressHUD.currentHUD {
                            hud.hide(animated: false)
                        }

                        if let tfaKey = results["tfaKey"] as? String {
                            apiOptions["tfaKey"] = tfaKey
                            self?.presentTfaSetupViewController(options: apiOptions, completion: completion)
                        } else {
                            self?.presentTfaCodeViewController(options: apiOptions, completion: completion)
                        }
                    } else {
                        if let topViewController = UIApplication.topViewController() {
                            let alertController = UIAlertController.alert(
                                ASCLocalization.Common.error,
                                message: String.localizedStringWithFormat(NSLocalizedString("The %@ server is not available.", comment: ""), baseUrl),
                                actions: []
                                ).okable()

                            topViewController.present(alertController, animated: true, completion: nil)
                        }

                        completion?(false)
                    }
                } else {
                    let errorInfo = ASCOnlyOfficeApi.errorInfo(by: response!)
                    let errorMessage = ASCOnlyOfficeApi.errorMessage(by: response!)

                    log.error(errorMessage)

                    if let hud = MBProgressHUD.currentHUD {
                        hud.hide(animated: false)
                    }

                    if errorInfo == nil && useProtocols.count > 0 {
                        if let topViewController = UIApplication.topViewController() {
                            let alertController = UIAlertController.alert(
                                ASCLocalization.Common.error,
                                message: String(format: "%@ %@", errorMessage, NSLocalizedString("Try to connect via another protocol?", comment: "")),
                                actions: [])
                                .okable() { _ in
                                    internalLogin()
                                }
                                .cancelable() { _ in
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
                                message: errorMessage,
                                actions: [])
                                .okable() { _ in
                                    completion?(false)
                            }

                            topViewController.present(alertController, animated: true, completion: nil)
                        } else {
                            completion?(false)
                        }
                    }
                }
            }
        }

        internalLogin()
    }
    
    func login(by type: ASCLoginType, options: Parameters, in navigationController: UINavigationController?, completion: ASCSignInComplateHandler? = nil) {
        self.navigationController = navigationController
        login(by: type, options: options, completion: completion)
    }

    func presentSmsCode(in navigationController: UINavigationController, options: Parameters, completion: ASCSignInComplateHandler?) {
        self.navigationController = navigationController
        presentSmsCodeViewController(options: options, completion: completion)
    }

    func presentPhoneNumber(in navigationController: UINavigationController, options: Parameters, completion: ASCSignInComplateHandler?) {
        self.navigationController = navigationController
        presentPhoneNumberViewController(options: options, completion: completion)
    }
    
}
