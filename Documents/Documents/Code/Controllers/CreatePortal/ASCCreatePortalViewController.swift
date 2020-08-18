//
//  ASCCreatePortalViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/29/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import MBProgressHUD
import Alamofire
import SkyFloatingLabelTextField
import Firebase

class ASCCreatePortalViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties
    var portal: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var isInfoPortal = false

    fileprivate let infoPortalSuffix = ".teamlab.info"
    
    @IBOutlet weak var portalField: ParkedTextField!
    @IBOutlet weak var firstNameField: SkyFloatingLabelTextField!
    @IBOutlet weak var lastNameField: SkyFloatingLabelTextField!
    @IBOutlet weak var emailField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordOneField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordTwoField: SkyFloatingLabelTextField!
    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        portalField?.parkedText = "." + domain(by: Locale.current.regionCode ?? "US")
        portalField?.selectedTitle = NSLocalizedString("Portal Address", comment: "")
        portalField?.title = NSLocalizedString("Portal Address", comment: "")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapTerms))
        termsLabel?.isUserInteractionEnabled = true
        termsLabel?.addGestureRecognizer(tapGesture)
        
        for field in [portalField, firstNameField, lastNameField, emailField, passwordOneField, passwordTwoField] {
            field?.titleFont = UIFont.systemFont(ofSize: 12)
            field?.lineHeight = UIDevice.screenPixel
            field?.selectedLineHeight = UIDevice.screenPixel * 2
            field?.titleFormatter = { $0.uppercased() }
            field?.placeholder = field?.placeholder?.uppercased()
            field?.placeholderFont = UIFont.systemFont(ofSize: 12)
        }
        
        if UIDevice.pad {
            topConstraint?.constant = 100
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    @objc func tapTerms(sender: UITapGestureRecognizer) {
        termsLabel?.alpha = 0.5
        
        UIView.animate(withDuration: 0.6) {
            self.termsLabel?.alpha = 1
        }
        
        if let url = URL(string: ASCConstants.Urls.legalTerms), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - Private

    private func valid(portal: String) -> Bool {
        if portal.length < 1 {
            portalField?.errorMessage = NSLocalizedString("Account name is empty", comment: "")
            portalField?.shake()
            return false
        }
        
        // The account name must be between 6 and 50 characters long.
        if !(6...50 ~= portal.count) {
            portalField?.errorMessage = NSLocalizedString("Account name is not valid", comment: "")
            portalField?.shake()
            showError(NSLocalizedString("The account name must be between 6 and 50 characters long", comment: ""))
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

        if !email.isValidEmail {
            emailField?.errorMessage = NSLocalizedString("Email is not valid", comment: "")
            emailField?.shake()
            return false
        }
        
        return true
    }
    
    private func valid(name: String) -> Bool {
        if name.length < 1 || !name.matches(pattern: "^[\\p{L}\\p{M}' \\.\\-]+$") {
            return false
        }
        
        return true
    }
    
    private func valid(password: String) -> Bool {
        if password.length < 1 {
            return false
        }
        
        return true
    }
    
    private func showNextStep() {
        IQKeyboardManager.shared.resignFirstResponder()

        let isInfoPortal = portalField?.typedText.trim().contains(infoPortalSuffix) ?? false

        guard
            let portal = portalField?
                .typedText
                .trim()
                .replacingOccurrences(of: infoPortalSuffix, with: ""),
            valid(portal: portal)
        else {
            return
        }
        
        guard let firstName = firstNameField?.text?.trim(), valid(name: firstName) else {
            firstNameField?.errorMessage = NSLocalizedString("Name is empty", comment: "")
            firstNameField?.shake()
            return
        }
        
        guard let lastName = lastNameField?.text?.trim(), valid(name: lastName) else {
            lastNameField?.errorMessage = NSLocalizedString("Name is empty", comment: "")
            lastNameField?.shake()
            return
        }
        
        guard let email = emailField?.text?.trim(), valid(email: email) else {
            emailField?.shake()
            return
        }
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Validation", comment: "Caption of the process")
        
        let baseApi = String(format: ASCConstants.Urls.apiSystemUrl, domain(by: isInfoPortal ? "DEBUG" : Locale.current.regionCode ?? "US"))
        let requestUrl = baseApi + "/" + ASCConstants.Urls.apiValidatePortalName
        let params: Parameters = [
            "portalName": portal
        ]
        
        AF.request(requestUrl, method: .post, parameters: params)
            .validate()
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    hud?.hide(animated: true)
                    
                    switch response.result {
                    case .success(let responseJson):
                        if
                            let responseJson = responseJson as? [String: Any],
                            let message = responseJson["message"] as? String
                        {
                            let status = ASCCreatePortalStatus(message)

                            switch status {
                            case .successReadyToRegister:
                                if let portalViewController = self.storyboard?.instantiateViewController(withIdentifier: "createPortalStepTwoController") as? ASCCreatePortalViewController {
                                    IQKeyboardManager.shared.enable = false

                                    portalViewController.portal = portal
                                    portalViewController.firstName = firstName
                                    portalViewController.lastName = lastName
                                    portalViewController.email = email
                                    portalViewController.isInfoPortal = isInfoPortal

                                    self.navigationController?.pushViewController(portalViewController, animated: true)
                                }

                            default:
                                self.showError(NSLocalizedString("Failed to check the name of the portal", comment: ""))
                            }
                        }
                    case .failure(let error):
                        log.error(error)

                        if
                            let data = response.data,
                            let responseString = String(data: data, encoding: .utf8),
                            let responseJson = responseString.toDictionary()
                        {
                            if let errorType = responseJson["error"] as? String {
                                let status = ASCCreatePortalStatus(errorType)

                                switch status {
                                case .failureTooShortError,
                                     .failurePortalNameExist,
                                     .failurePortalNameIncorrect:
                                    self.showError(status.description)
                                default:
                                    if let errorMessage = responseJson["message"] as? String {
                                        self.showError(errorMessage)
                                    } else {
                                        self.showError(NSLocalizedString("Failed to check the name of the portal", comment: ""))
                                    }
                                }
                            } else {
                                self.showError(error.localizedDescription)
                            }
                        } else {
                            self.showError(error.localizedDescription)
                        }
                    }
                })
        }
    }
    
    private func createPortal() {
        IQKeyboardManager.shared.resignFirstResponder()
        
        guard let passwordOne = passwordOneField?.text?.trim(), valid(password: passwordOne) else {
            passwordOneField?.errorMessage = NSLocalizedString("Password is empty", comment: "")
            passwordOneField?.shake()
            return
        }
        
        guard let passwordTwo = passwordTwoField?.text?.trim(), valid(password: passwordTwo) else {
            passwordTwoField?.errorMessage = NSLocalizedString("Password is empty", comment: "")
            passwordTwoField?.shake()
            return
        }
        
        if passwordOne != passwordTwo {
            passwordTwoField?.errorMessage = NSLocalizedString("Passwords do not match", comment: "")
            passwordTwoField?.shake()
            return
        }
        
        guard let firstName = firstName else {
            return
        }
        
        guard let lastName = lastName else {
            return
        }
        
        guard let email = email else {
            return
        }
        
        guard let language = Locale.preferredLanguages.first else {
            return
        }
        
        guard let portalName = portal else {
            return
        }
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Registration", comment: "")
        
        let baseApi = String(format: ASCConstants.Urls.apiSystemUrl, domain(by: isInfoPortal ? "DEBUG" : Locale.current.regionCode ?? "US"))
        let requestUrl = baseApi + "/" + ASCConstants.Urls.apiRegistrationPortal
        let params: Parameters = [
            "firstName"      : firstName,
            "lastName"       : lastName,
            "email"          : email,
            "phone"          : "",
            "portalName"     : portalName,
            "partnerId"      : "",
            "industry"       : 0,
            "timeZoneName"   : TimeZone.current.identifier,
            "language"       : language,
            "password"       : passwordOne,
            "appKey"         : ASCConstants.Keys.portalRegistration
        ]
        
        AF.request(requestUrl, method: .post, parameters: params)
            .validate()
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    hud?.hide(animated: true)
                    
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let tenant = responseJson["tenant"] as? [String: Any], let domain = tenant["domain"] as? String {
                                Analytics.logEvent(ASCConstants.Analytics.Event.createPortal, parameters: [
                                    "portal": domain,
                                    "email": email
                                    ]
                                )
                                self.login(address: domain)
                            } else {
                                self.showError(NSLocalizedString("Unable to get information about the portal", comment: ""))
                            }
                        }
                    case .failure(let error):
                        log.error(error)

                        if
                            let data = response.data,
                            let responseString = String(data: data, encoding: .utf8),
                            let responseJson = responseString.toDictionary()
                        {
                            if let errorType = responseJson["error"] as? String {
                                let status = ASCCreatePortalStatus(errorType)

                                switch status {
                                case .failurePassPolicyError,
                                     .failureTooShortError:
                                    self.showError(status.description)
                                default:
                                    if let errorMessage = responseJson["message"] as? String {
                                        self.showError(errorMessage)
                                    } else {
                                        self.showError(NSLocalizedString("Failed to check the name of the portal", comment: ""))
                                    }
                                }
                            } else {
                                self.showError(error.localizedDescription)
                            }
                        } else {
                            self.showError(error.localizedDescription)
                        }
                    }
                })
        }
    }

    private func login(address: String) {
        guard let login = email else {
            return
        }

        guard let password = passwordOneField?.text?.trim() else {
            return
        }

        let api = ASCOnlyOfficeApi.shared
        let baseUrl = "https://" + address

        api.baseUrl = baseUrl

        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

        let parameters: Parameters = [
            "portal": baseUrl,
            "provider": "email",
            "userName": login,
            "password": password
        ]

        ASCSignInController.shared.login(by: .email, options: parameters, in: navigationController) { [weak self] success in
            if success {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: 2)

                NotificationCenter.default.post(name: ASCConstants.Notifications.loginOnlyofficeCompleted, object: nil)

                self?.dismiss(animated: true, completion: nil)
            } else {
                hud?.hide(animated: true)
            }
        }
    }
    
    private func showError(_ message: String) {
        UIAlertController.showError(in: self, message: message)
    }
    
    // MARK: - Actions
    
    @IBAction func onFinalStep(_ sender: UIButton) {
        showNextStep()
    }
    
    @IBAction func onCreate(_ sender: UIButton) {
        createPortal()
    }
    
    // MARK: - Text Field Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            if restorationIdentifier == "createPortalStepOneController" {
                showNextStep()
            } else {
                createPortal()
            }
            return true
        }        
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let floatingLabelTextField = textField as? SkyFloatingLabelTextField {
            floatingLabelTextField.errorMessage = ""
        }
        return true
    }
}

extension ASCCreatePortalViewController {
    func domain(by regin: String) -> String {
        let domainRegion: [String: String] = ASCConstants.Urls.domainRegions
        return domainRegion[regin] ?? ASCConstants.Urls.defaultDomainRegions
    }
}
