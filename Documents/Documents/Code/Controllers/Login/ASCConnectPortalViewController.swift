//
//  ASCConnectPortalViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/1/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import IQKeyboardManagerSwift
import Alamofire
import MBProgressHUD

class ASCConnectPortalViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var createPortalButton: UIButton!
    @IBOutlet weak var addressField: SkyFloatingLabelTextField!
    @IBOutlet weak var infoLabel: UILabel!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressField?.titleFont = UIFont.systemFont(ofSize: 12)
        addressField?.lineHeight = UIDevice.screenPixel
        addressField?.selectedLineHeight = UIDevice.screenPixel * 2
        addressField?.titleFormatter = { $0.uppercased() }
        addressField?.placeholder = NSLocalizedString("Enter Portal Address", comment: "").uppercased()
        addressField?.placeholderFont = UIFont.systemFont(ofSize: 12)
        
        // Decorate info label
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .center
        infoLabel?.text = String.localizedStringWithFormat(NSLocalizedString("Connect to your %@ cloud to store files online and collaborate on documents in real time", comment: "Footer text"), ASCConstants.Name.appNameShort)
        let attributedString = NSMutableAttributedString(string: infoLabel?.text ?? "")
        attributedString.addAttribute(.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        
        infoLabel?.attributedText = attributedString
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        if let navigationController = navigationController {
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.shadowImage = UIImage()
            
            if navigationController.viewControllers.count < 2 {
                navigationItem.leftBarButtonItem = UIBarButtonItem(
                    title: NSLocalizedString("Close", comment: ""), 
                    style: .plain, 
                    target: self, 
                    action: #selector(onClose(_:))
                )
            }
        }
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

        view.endEditing(true)
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
    
    private func ipAddress(of host: String) -> String? {
        let host = CFHostCreateWithName(nil, host as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
            let theAddress = addresses.firstObject as? NSData {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let numAddress = String(cString: hostname)
                log.info(numAddress)
                
                return numAddress
            }
        }
        
        return nil
    }
    
    private func validatePortal(validation: @escaping (Bool, String?, [String: Any]?)->()) {
        guard let portalUrl = addressField?.text?.trim() else {
            validation(false, NSLocalizedString("Address is empty", comment: ""), nil)
            return
        }
        
        if portalUrl.length < 1 {
            validation(false, NSLocalizedString("Address is empty", comment: ""), nil)
            return
        }

        let api = ASCOnlyOfficeApi.shared

        // Cleanup portal capabilities
        api.capabilities = nil

        var useProtocols = [String]()
        
        if !portalUrl.matches(pattern: "^https?://") {
            useProtocols += ["https://", "http://"]
        }
        
        func checkPortal() {
            var baseUrl = portalUrl
            
            if let portalProtocol = useProtocols.first {
                baseUrl = portalProtocol + portalUrl
                useProtocols.removeFirst()
            }
            
            // Setup API manager
            api.baseUrl = baseUrl
            
            ASCOnlyOfficeApi.get(ASCOnlyOfficeApi.apiCapabilities) { [weak self] results, error, response in
                guard let strongSelf = self else { return }
                
                if let results = results as? [String: Any] {
                    // Setup portal capabilities
                    api.capabilities = ASCPortalCapabilities(JSON: results)

                    validation(true, nil, results)
                } else {
                    var errorInfo: [String: Any]?
                    var errorMessage = NSLocalizedString("Failed to check portal availability.", comment: "")

                    if let response = response {
                        errorInfo = ASCOnlyOfficeApi.errorInfo(by: response)
                        errorMessage = ASCOnlyOfficeApi.errorMessage(by: response)
                    }

                    log.error(errorMessage)
                    
                    if errorInfo == nil && useProtocols.count > 0 {
                        let alertController = UIAlertController.alert(
                            NSLocalizedString("Error", comment: ""),
                            message: String(format: "%@ %@", errorMessage, NSLocalizedString("Try to connect via another protocol?", comment: "")),
                            actions: [])
                            .okable() { _ in
                                checkPortal()
                            }
                            .cancelable() { _ in
                                validation(false, nil, nil)
                        }
                        
                        strongSelf.present(alertController, animated: true, completion: nil)
                    } else {
                        api.baseUrl = nil
                        validation(true, NSLocalizedString("Failed to check portal availability.", comment: ""), nil)
                    }
                }
            }
        }
        
        checkPortal()
    }
    
    private func showSignIn() {
        let signinViewController = ASCSignInViewController.instantiate(from: Storyboard.login)
        signinViewController.portal = addressField?.text?.trim()
        navigationController?.pushViewController(signinViewController, animated: true)
    }
    
    // MARK: - UITextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onContinue(textField)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let floatingLabelTextField = textField as? SkyFloatingLabelTextField {
            floatingLabelTextField.errorMessage = ""
        }
        return true
    }
    
    // MARK: - Actions
    
    @IBAction func onClose(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onContinue(_ sender: Any) {
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Connecting", comment: "Caption of the process")
        
        view.endEditing(true)
        
        validatePortal { [weak self] sussess, error, capabilities in
            hud?.hide(animated: true)
            
            guard let strongSelf = self else { return }
            if !sussess {
                strongSelf.addressField?.shake()
                strongSelf.addressField?.errorMessage = error ?? NSLocalizedString("The portal address is invalid", comment: "")
            } else if let error = error {
                let alertController = UIAlertController(
                    title: NSLocalizedString("Error", comment:""),
                    message: error,
                    preferredStyle: .alert,
                    tintColor: nil
                )
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Continue anyway", comment: ""), style: .default, handler: { action in
                    strongSelf.showSignIn()
                }))
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { action in
                    //
                }))
                
                alertController.view.tintColor = strongSelf.view.tintColor
                strongSelf.present(alertController, animated: true, completion: nil)
            } else {
                strongSelf.addressField?.errorMessage = nil
                strongSelf.showSignIn()
            }
        }
    }
    

}
