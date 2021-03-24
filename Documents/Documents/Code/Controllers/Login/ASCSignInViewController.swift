//
//  ASCSignInViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/1/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire
import SkyFloatingLabelTextField
import IQKeyboardManagerSwift
import MBProgressHUD

class ASCSignInViewController: UIViewController, UITextFieldDelegate {
    static let identifier = String(describing: ASCSignInViewController.self)

    // MARK: - Properties
    var portal: String?
    var email: String?
    var renewal: Bool = false

    private let facebookSignInController = ASCFacebookSignInController()
    private let googleSignInController = ASCGoogleSignInController()
    
    @IBOutlet weak var emailField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordField: SkyFloatingLabelTextField!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var ssoButton: UIButton!
    @IBOutlet weak var forgotButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var loginByLabel: UILabel!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel?.text = portal
        emailField?.text = email

        let capabilities = ASCOnlyOfficeApi.shared.capabilities

        if capabilities?.ldapEnabled ?? false {
            emailField?.placeholder = NSLocalizedString("Login", comment: "")
        } else {
            emailField?.placeholder = NSLocalizedString("Email", comment: "")
        }
        passwordField?.placeholder = NSLocalizedString("Password", comment: "")
                
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

            loginByLabel?.isHidden = !(allowFacebook || allowGoogle)
            facebookButton?.isHidden = !allowFacebook
            googleButton?.isHidden = !allowGoogle
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
        IQKeyboardManager.shared.shouldShowToolbarPlaceholder = false
        IQKeyboardManager.shared.shouldToolbarUsesTextFieldTintColor = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        IQKeyboardManager.shared.enable = false
        IQKeyboardManager.shared.enableAutoToolbar = false
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
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
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        if !emailTest.evaluate(with: email) {
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

    // MARK: - Text Field Delegate
    
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
    
    // MARK: - Actions
    
    @IBAction func onForgotPassword(_ sender: Any) {
        if var portal = portal {
            if !portal.matches(pattern: "^https?://") {
                portal = "https://\(portal)"
            }
            
            if let portalUrl = URL(string: String(format: ASCConstants.Urls.apiForgetPassword, portal)),
                UIApplication.shared.canOpenURL(portalUrl)
            {
                UIApplication.shared.open(portalUrl, options: [:], completionHandler: nil)
            }
        }
    }
    
    @IBAction func onEmailLogin(_ sender: Any) {
        guard let portal = ASCOnlyOfficeApi.shared.baseUrl ?? portal?.trim() else {
            return
        }
        
        guard let email = emailField?.text?.trim() else {
            return
        }

        if ASCOnlyOfficeApi.shared.capabilities?.ldapEnabled ?? false {
            if !valid(login: email) {
                return
            }
        } else {
            if !valid(email: email) {
                return
            }
        }
        
        guard let password = passwordField?.text?.trim(), valid(password: password) else {
            return
        }
        
        view.endEditing(true)
        
        let parameters: Parameters = [
            "portal": portal,
            "userName": email,
            "password": password
        ]
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")
        
        ASCSignInController.shared.login(by: .email,
                                         options: parameters,
                                         in: navigationController)
        { [weak self] success in
            if success {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: 2)

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
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")
        
        facebookSignInController.signIn(controller: self) { [weak self] token, error in
            guard let strongSelf = self else { return }

            if let accessToken = token {
                let parameters: Parameters = [
                    "portal": strongSelf.portal ?? "",
                    "facebookToken": accessToken
                ]
                
                ASCSignInController.shared.login(by: .facebook,
                                                 options: parameters,
                                                 in: strongSelf.navigationController)
                { success in
                    if success {
                        hud?.setSuccessState()
                        hud?.hide(animated: true, afterDelay: 2)

                        NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)
                        
                        strongSelf.dismiss(animated: true, completion: nil)
                    } else {
                        hud?.hide(animated: true)
                    }
                }
            } else {
                hud?.hide(animated: true)
                
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
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")
        
        googleSignInController.signIn(controller: self) { [weak self] token, userData, error in
            guard let strongSelf = self else { return }

            if let accessToken = token {
                let parameters: Parameters = [
                    "portal": strongSelf.portal ?? "",
                    "googleToken": accessToken
                ]
                
                ASCSignInController.shared.login(by: .google,
                                                 options: parameters,
                                                 in: strongSelf.navigationController)
                { success in
                    if success {
                        hud?.setSuccessState()
                        hud?.hide(animated: true, afterDelay: 2)

                        // Notify
                        NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)
                        
                        strongSelf.dismiss(animated: true, completion: nil)
                    } else {
                        hud?.hide(animated: true)
                    }
                }
            } else {
                hud?.hide(animated: true)
                
                if let _ = error {
                    UIAlertController.showError(
                        in: strongSelf,
                        message: NSLocalizedString("Unable to get information about the user.", comment: "")
                    )
                }
            }
        }
    }
    
    @IBAction func onSSOLogin(_ sender: UIButton) {
        view.endEditing(true)
        
        if let ssoNavigationController = storyboard?.instantiateViewController(withIdentifier: "ASCSSOSignInNavigationController") as? UINavigationController {
            present(ssoNavigationController, animated: true, completion: { [weak self] in
                if let ssoViewController = ssoNavigationController.topViewController as? ASCSSOSignInController {
                    let requestQueue = OperationQueue()
                    requestQueue.maxConcurrentOperationCount = 1

                    var lastErrorMsg: String?
                    var hud: MBProgressHUD?
                    
                    // Sign in with SSO
                    requestQueue.addOperation {
                        let semaphore = DispatchSemaphore(value: 0)
                        DispatchQueue.main.async {
                            ssoViewController.signIn(ssoUrl: ASCOnlyOfficeApi.shared.capabilities?.ssoUrl ?? "", handler: { token, error in
                                defer { semaphore.signal() }
                                
                                if let error = error {
                                    lastErrorMsg = String(format: NSLocalizedString("Please retry. \n\n If the problem persists contact us and mention this error code: SSO - %@", comment: ""), error.localizedDescription)
                                } else if let token = token, token.length > 0 {
                                    hud = MBProgressHUD.showTopMost()
                                    hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")
                                    
                                    ASCOnlyOfficeApi.shared.token = token
                                    ASCOnlyOfficeApi.shared.expires = Date().adding(.year, value: 100)
                                }
                            })
                        }
                        
                        semaphore.wait()
                    }
                    
                    // Get server version
                    requestQueue.addOperation {
                        if nil == lastErrorMsg {
                            let semaphore = DispatchSemaphore(value: 0)
                            ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiServersVersion) { results, error, response in
                                defer { semaphore.signal() }
                                
                                if let versions = results as? [String: Any] {
                                    if let communityServer = versions["communityServer"] as? String {
                                        ASCOnlyOfficeApi.shared.serverVersion = communityServer
                                    }
                                }
                                
                                // Init ONLYOFFICE provider
                                if let baseUrl = ASCOnlyOfficeApi.shared.baseUrl, let token = ASCOnlyOfficeApi.shared.token {
                                    ASCFileManager.onlyofficeProvider = ASCOnlyofficeProvider(baseUrl: baseUrl, token: token)
                                    ASCFileManager.provider = ASCFileManager.onlyofficeProvider
                                    ASCFileManager.storeProviders()
                                }
                            }
                            
                            semaphore.wait()
                        }
                    }
                    
                    // Fetch user info
                    requestQueue.addOperation {
                        if nil == lastErrorMsg {
                            let semaphore = DispatchSemaphore(value: 0)
                            if let onlyofficeProvider = ASCFileManager.onlyofficeProvider?.copy() as? ASCOnlyofficeProvider {
                                onlyofficeProvider.userInfo { success, error in
                                    defer { semaphore.signal() }
                                    
                                    if success {
                                        ASCFileManager.onlyofficeProvider?.user = onlyofficeProvider.user
                                    } else {
                                        lastErrorMsg = NSLocalizedString("User authentication failed", comment: "")
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
                            
                            if let lastErrorMsg = lastErrorMsg {
                                hud?.hide(animated: false)
                                
                                UIAlertController.showError(
                                    in: strongSelf.parent ?? strongSelf,
                                    message: lastErrorMsg
                                )
                            } else {
                                hud?.setSuccessState()
                                hud?.hide(animated: true, afterDelay: 1)
                                
                                // Registration device into the portal
                                ASCOnlyOfficeApi.post(ASCOnlyOfficeApi.apiDeviceRegistration, parameters: ["type": 2], completion: { (_, _, _) in
                                    // 2 - IOSDocuments
                                })
                                
                                if let portal = ASCOnlyOfficeApi.shared.baseUrl?.lowercased() {
                                    ASCAnalytics.logEvent(ASCConstants.Analytics.Event.loginPortal, parameters: [
                                        "portal": portal,
                                        "provider": ASCLoginType.sso
                                    ])
                                }
                                
                                ASCEditorManager.shared.fetchDocumentService { _,_,_  in }
                                
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
}
