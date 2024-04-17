//
//  ASCSignInViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/1/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Alamofire
import AuthenticationServices
import IQKeyboardManagerSwift
import MBProgressHUD
import SkyFloatingLabelTextField
import UIKit

class ASCSignInViewController: ASCBaseViewController {
    static let identifier = String(describing: ASCSignInViewController.self)

    override class var storyboard: Storyboard { return Storyboard.login }

    // MARK: - Properties

    var portal: String?
    var email: String?
    var renewal: Bool = false

    private let facebookSignInController = ASCFacebookSignInController()
    private let googleSignInController = ASCGoogleSignInController()
    @available(iOS 13.0, *)
    private lazy var appleIdSignInController = ASCAppleIdSignInController()
    private var signInWithLdap: Bool = false

    // MARK: - Outlets

    @IBOutlet var emailField: SkyFloatingLabelTextField!
    @IBOutlet var passwordField: SkyFloatingLabelTextField!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var ssoButton: ASCButtonStyle!
    @IBOutlet var forgotButton: UIButton!
    @IBOutlet var facebookButton: UIButton!
    @IBOutlet var googleButton: UIButton!
    @IBOutlet var microsoftButton: UIButton!
    @IBOutlet var loginByLabel: UILabel!
    @IBOutlet var appleIdButton: UIButton!
    @IBOutlet var signInButtonsStack: UIStackView!
    @IBOutlet weak var signInWithLdapStack: UIStackView!
    @IBOutlet weak var signInWithLdapButton: UIButton!
    @IBOutlet weak var signInWithLdapLabel: UILabel!
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        addressLabel?.text = portal
        emailField?.text = email

        ssoButton?.styleType = .bordered

        let capabilities = OnlyofficeApiClient.shared.capabilities
        capabilities?.ldapEnabled = true
        if capabilities?.ldapEnabled ?? false {
            emailField?.placeholder = NSLocalizedString("Email adress", comment: "")
        } else {
            emailField?.placeholder = NSLocalizedString("Email", comment: "")
        }
        passwordField?.placeholder = NSLocalizedString("Password", comment: "")
        signInWithLdapButton.setTitle("", for: .normal)

        for field in [emailField, passwordField] {
            field?.titleFont = UIFont.systemFont(ofSize: 12)
            field?.lineHeight = UIDevice.screenPixel
            field?.selectedLineHeight = UIDevice.screenPixel * 2
            field?.titleFormatter = { $0.uppercased() }
            field?.placeholder = field?.placeholder?.uppercased()
            field?.placeholderFont = UIFont.systemFont(ofSize: 12)
        }

        for button in [forgotButton, ssoButton] {
            button?.titleLabel?.numberOfLines = 1
            button?.titleLabel?.adjustsFontSizeToFitWidth = true
            button?.titleLabel?.lineBreakMode = .byClipping
        }

        appleIdButton?.imageView?.layer.cornerRadius = 4

        let ssoUrl = capabilities?.ssoUrl ?? ""
        var ssoLabel = capabilities?.ssoLabel ?? ""

        if ssoLabel.isEmpty {
            ssoLabel = NSLocalizedString("Single Sign-on", comment: "")
        }

        if ssoUrl.isEmpty {
            ssoButton?.removeFromSuperview()
        } else {
            ssoButton.setTitle(
                String(format: NSLocalizedString("Login by %@", comment: ""), ssoLabel),
                for: .normal
            )
        }

        // Layout provider login buttons
        if let capabilities = capabilities {
            let allowFacebook = capabilities.providers.contains(.facebook)
            let allowGoogle = capabilities.providers.contains(.google)
            let allowAppleId = capabilities.providers.contains(.appleid)
            let allowMicrosoft = capabilities.providers.contains(.microsoft)
            let allowLdap = capabilities.ldapEnabled

            loginByLabel?.isHidden = !(allowFacebook || allowGoogle || allowAppleId || allowMicrosoft)
            facebookButton?.isHidden = !allowFacebook
            googleButton?.isHidden = !allowGoogle
            signInWithLdapStack.isHidden = !allowLdap

            if #available(iOS 13.0, *) {
                appleIdButton?.isHidden = !allowAppleId
            } else {
                appleIdButton?.isHidden = true
            }

            microsoftButton?.isHidden = !allowMicrosoft
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        emailField?.isHidden = renewal

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let passwordField = passwordField as? ASCFloatingLabelTextField {
            passwordField.rightPadding = forgotButton.width + 10
        }

        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        IQKeyboardManager.shared.toolbarConfiguration.placeholderConfiguration.showPlaceholder = false
        IQKeyboardManager.shared.toolbarConfiguration.useTextFieldTintColor = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if KeyboardManagerHelper.disablingKeyboardToolbarByScreen == nil {
            KeyboardManagerHelper.disablingKeyboardToolbarByScreen = ASCSignInViewController.identifier
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if KeyboardManagerHelper.disablingKeyboardToolbarByScreen == ASCSignInViewController.identifier || KeyboardManagerHelper.disablingKeyboardToolbarByScreen == nil {
            IQKeyboardManager.shared.enable = false
            IQKeyboardManager.shared.enableAutoToolbar = false
            KeyboardManagerHelper.disablingKeyboardToolbarByScreen = nil
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Private

    private func valid(login: String) -> Bool {
        if login.length < 1 {
            emailField?.errorMessage = NSLocalizedString("Login is empty", comment: "")
            emailField?.shake()
            return false
        }

        return true
    }

    private func valid(email: String) -> Bool {
        if email.length < 1 {
            emailField?.errorMessage = NSLocalizedString("Email is empty", comment: "")
            emailField?.shake()
            return false
        }

        if !email.isValidOnlyofficeEmail {
            emailField?.errorMessage = NSLocalizedString("Email is not valid", comment: "")
            emailField?.shake()
            return false
        }

        return true
    }

    private func valid(password: String) -> Bool {
        if password.length < 1 {
            passwordField?.errorMessage = NSLocalizedString("Password is empty", comment: "")
            passwordField?.shake()
            return false
        }

        return true
    }

    // MARK: - Actions
    
    @IBAction func onSignInAsLdapUser(_ sender: Any) {
        signInWithLdap.toggle()
        signInWithLdapButton.setImage(signInWithLdap 
                                      ? UIImage(systemName: "checkmark.circle.fill")
                                      : UIImage(systemName: "circle"), for: .normal)
        emailField.placeholder = signInWithLdap 
        ? NSLocalizedString("User name", comment: "").uppercased()
        : NSLocalizedString("Email adress", comment: "").uppercased()
    }
    
    @IBAction func onForgotPassword(_ sender: Any) {
        navigator.navigate(to: .recoveryPasswordByEmail)
    }

    @IBAction func onEmailLogin(_ sender: Any) {
        guard let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString ?? portal?.trimmed else {
            return
        }

        guard let email = emailField?.text?.trimmed else {
            return
        }

        if OnlyofficeApiClient.shared.capabilities?.ldapEnabled ?? false {
            if !valid(login: email) {
                return
            }
        } else {
            if !valid(email: email) {
                return
            }
        }

        guard let password = passwordField?.text?.trimmed, valid(password: password) else {
            return
        }

        view.endEditing(true)

        let authRequest = OnlyofficeAuthRequest()
        authRequest.provider = .email
        authRequest.portal = portal
        authRequest.userName = email
        authRequest.password = password

        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

        ASCSignInController.shared.login(by: authRequest, in: navigationController) { [weak self] success in
            if success {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: .twoSecondsDelay)

                // Notify
                NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)

                self?.dismiss(animated: true, completion: nil)
            } else {
                hud?.hide(animated: true)
            }
        }
    }

    @IBAction func onFacebookLogin(_ sender: UIButton) {
        view.endEditing(true)

        facebookSignInController.signIn(controller: self) { [weak self] token, error in
            guard let strongSelf = self else { return }

            if let accessToken = token {
                let authRequest = OnlyofficeAuthRequest()
                authRequest.provider = .facebook
                authRequest.portal = strongSelf.portal
                authRequest.accessToken = accessToken

                let hud = MBProgressHUD.showTopMost()
                hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

                ASCSignInController.shared.login(by: authRequest, in: strongSelf.navigationController) { success in
                    if success {
                        hud?.setSuccessState()
                        hud?.hide(animated: true, afterDelay: .twoSecondsDelay)

                        NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)

                        strongSelf.dismiss(animated: true, completion: nil)
                    } else {
                        hud?.hide(animated: true)

                        UIAlertController.showError(
                            in: strongSelf,
                            message: NSLocalizedString("User authentication failed", comment: "")
                        )
                    }
                }
            } else {
                if let _ = error {
                    UIAlertController.showError(
                        in: strongSelf,
                        message: NSLocalizedString("Unable to get information about the user.", comment: "")
                    )
                }
            }
        }
    }

    @IBAction func onGoogleLogin(_ sender: UIButton) {
        view.endEditing(true)

        googleSignInController.signIn(controller: self) { [weak self] token, userData, error in
            guard let strongSelf = self else { return }

            if let accessToken = token {
                let authRequest = OnlyofficeAuthRequest()
                authRequest.provider = .google
                authRequest.portal = strongSelf.portal
                authRequest.accessToken = accessToken

                let hud = MBProgressHUD.showTopMost()
                hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

                ASCSignInController.shared.login(by: authRequest, in: strongSelf.navigationController) { success in
                    if success {
                        hud?.setSuccessState()
                        hud?.hide(animated: true, afterDelay: .twoSecondsDelay)

                        // Notify
                        NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)

                        strongSelf.dismiss(animated: true, completion: nil)
                    } else {
                        hud?.hide(animated: true)

                        UIAlertController.showError(
                            in: strongSelf,
                            message: NSLocalizedString("User authentication failed", comment: "")
                        )
                    }
                }
            } else {
                if let _ = error {
                    UIAlertController.showError(
                        in: strongSelf,
                        message: NSLocalizedString("Unable to get information about the user.", comment: "")
                    )
                }
            }
        }
    }

    @available(iOS 13, *)
    @IBAction func onAppleIdLogin(_ sender: UIButton) {
        appleIdSignInController.signIn(controller: self) { result in
            switch result {
            case let .success(appleIdAuthorizationCode):
                let authRequest = OnlyofficeAuthRequest()
                authRequest.provider = .appleid
                authRequest.portal = self.portal
                authRequest.codeOauth = appleIdAuthorizationCode

                let hud = MBProgressHUD.showTopMost()
                hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

                ASCSignInController.shared.login(by: authRequest, in: self.navigationController) { success in
                    if success {
                        hud?.setSuccessState()
                        hud?.hide(animated: true, afterDelay: .twoSecondsDelay)

                        NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)

                        self.dismiss(animated: true, completion: nil)
                    } else {
                        hud?.hide(animated: true)

                        UIAlertController.showError(
                            in: self,
                            message: NSLocalizedString("User authentication failed", comment: "")
                        )
                    }
                }
            case let .failure(error):
                UIAlertController.showError(
                    in: self,
                    message: error.localizedDescription
                )
            }
        }
    }

    @IBAction func onMicrosoftLogin(_ sender: UIButton) {
        view.endEditing(true)

        let oauth2VC = ASCConnectStorageOAuth2ViewController.instantiate(from: Storyboard.connectStorage)
        let microsoftController = ASCMicrosoftSignInController()
        microsoftController.clientId = ASCConstants.Clouds.Microsoft.clientId
        microsoftController.redirectUrl = ASCConstants.Clouds.Microsoft.redirectUri
        oauth2VC.responseType = .code
        oauth2VC.complation = { [weak self] info in
            guard let self = self else { return }
            if let codeOauth = info["code"] as? String {
                let authRequest = OnlyofficeAuthRequest()
                authRequest.provider = .microsoft
                authRequest.portal = self.portal
                authRequest.codeOauth = codeOauth
                let hud = MBProgressHUD.showTopMost()
                hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

                ASCSignInController.shared.login(by: authRequest, in: self.navigationController) { success in
                    if success {
                        hud?.setSuccessState()
                        hud?.hide(animated: true, afterDelay: .twoSecondsDelay)

                        NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)

                        self.dismiss(animated: true, completion: nil)
                    } else {
                        hud?.hide(animated: true)
                        UIAlertController.showError(in: self, message: NSLocalizedString("User authentication failed", comment: ""))
                    }
                }
            } else if let error = info["error"] as? String {
                UIAlertController.showError(in: self, message: error)
            }
        }
        oauth2VC.delegate = microsoftController
        oauth2VC.title = "Microsoft"

        navigationController?.pushViewController(oauth2VC, animated: true)
    }

    @IBAction func onSSOLogin(_ sender: UIButton) {
        view.endEditing(true)

        let ssoNavigationController = StoryboardScene.Login.ascssoSignInNavigationController.instantiate()

        present(ssoNavigationController, animated: true, completion: { [weak self] in
            if let ssoViewController = ssoNavigationController.topViewController as? ASCSSOSignInController {
                let api = OnlyofficeApiClient.shared

                let requestQueue = OperationQueue()
                requestQueue.maxConcurrentOperationCount = 1

                var lastError: Error?
                var hud: MBProgressHUD?

                // Sign in with SSO
                requestQueue.addOperation {
                    let semaphore = DispatchSemaphore(value: 0)
                    DispatchQueue.main.async {
                        ssoViewController.signIn(ssoUrl: api.capabilities?.ssoUrl ?? "", handler: { token, error in
                            defer { semaphore.signal() }

                            if let error = error {
                                lastError = NetworkingError.apiError(
                                    error: OnlyofficeServerError.unknown(
                                        message: String(
                                            format: NSLocalizedString("Please retry. \n\n If the problem persists contact us and mention this error code: SSO - %@", comment: ""), error.localizedDescription
                                        )
                                    )
                                )
                            } else if let token = token, token.length > 0 {
                                hud = MBProgressHUD.showTopMost()
                                hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

                                // Set api
                                api.baseURL = api.baseURL
                                api.token = token
                                api.expires = Date().adding(.year, value: 100)
                            }
                        })
                    }

                    semaphore.wait()
                }

                // Get server version
                requestQueue.addOperation {
                    if lastError == nil,
                       let token = api.token,
                       let baseUrl = api.baseURL?.absoluteString
                    {
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
                        if let onlyofficeProvider = ASCFileManager.onlyofficeProvider?.copy() as? ASCOnlyofficeProvider {
                            onlyofficeProvider.userInfo { success, error in
                                defer { semaphore.signal() }

                                if success {
                                    ASCFileManager.onlyofficeProvider?.user = onlyofficeProvider.user
                                } else {
                                    lastError = NetworkingError.apiError(error: OnlyofficeServerError.unauthorized)
                                }
                            }
                        }
                        semaphore.wait()
                    }
                }

                DispatchQueue.global(qos: .background).async { [weak self] in
                    requestQueue.waitUntilAllOperationsAreFinished()

                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }

                        if let error = lastError {
                            hud?.hide(animated: false)

                            UIAlertController.showError(
                                in: strongSelf.parent ?? strongSelf,
                                message: error.localizedDescription
                            )
                        } else {
                            hud?.setSuccessState()
                            hud?.hide(animated: true, afterDelay: .oneSecondDelay)

                            OnlyofficeApiClient.request(
                                OnlyofficeAPI.Endpoints.Auth.deviceRegistration,
                                ["type": OnlyofficeApplicationType.documents.rawValue]
                            )

                            // Registration for push notification
                            ASCPushNotificationManager.requestRegister()

                            // Analytics
                            if let portal = OnlyofficeApiClient.shared.baseURL?.absoluteURL {
                                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.loginPortal, parameters: [
                                    ASCAnalytics.Event.Key.portal: portal,
                                    ASCAnalytics.Event.Key.provider: ASCLoginType.sso.rawValue,
                                ])
                            }

                            ASCEditorManager.shared.fetchDocumentService { _, _, _ in }

                            // Notify
                            NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)

                            strongSelf.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        })
    }
}

// MARK: - Text Field Delegate

extension ASCSignInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1

        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            onEmailLogin(textField)
            return true
        }

        return false
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        if let floatingLabelTextField = textField as? SkyFloatingLabelTextField {
            floatingLabelTextField.errorMessage = ""
        }
        return true
    }
}
