//
//  ASCPasswordRecoveryViewController.swift
//  Documents
//
//  Created by Иван Гришечко on 26.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import MBProgressHUD
import Alamofire
import IQKeyboardManagerSwift

class ASCPasswordRecoveryViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var recoveryTitle: UILabel!
    @IBOutlet weak var instruction: UILabel!
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var sendButton: UIButton!
    
    private let portal: String? = nil
    private var responseText: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendButton.isUserInteractionEnabled = false
        emailTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 124.0
    }
    
    private func valid(email: String) -> Bool {
        if email.length < 1 {
            emailTextField?.errorMessage = NSLocalizedString("Email is empty", comment: "")
            emailTextField?.shake()
            return false
        }
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        if !emailTest.evaluate(with: email) {
            emailTextField?.errorMessage = NSLocalizedString("Email is not valid", comment: "")
            emailTextField?.shake()
            return false
        }
        
        return true
    }
    
    private func presentEmailSentVC(responseText: String) {
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        guard let emailSentVC = storyBoard.instantiateViewController(withIdentifier: "ASCEmailSentViewController") as? ASCEmailSentViewController else { return }
        emailSentVC.email = emailTextField?.text?.trim()
        navigationController?.show(emailSentVC, sender: self)
    }
    
    @IBAction func onSendButton(_ sender: Any) {
        guard let portal = ASCOnlyOfficeApi.shared.baseUrl ?? portal?.trim() else {
            return
        }
        
        guard let email = emailTextField?.text?.trim() else {
            return
        }
        
        if !valid(email: email) {
            return
        }
        
        view.endEditing(true)
        
        let parameters: Parameters = [
            "email": email,
            "portal": portal
        ]
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Sending instructions", comment: "Caption of the process")
        ASCPasswordRecoveryController.shared.forgotPassword(portalUrl: portal,options: parameters)
            { [weak self] result in
            switch result {
            case .success(let response):
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: 2)
                
                self?.presentEmailSentVC(responseText: response.response)
            case .failure(let error):
                log.error(error)
                hud?.hide(animated: true)
            }
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
            sendButton.isUserInteractionEnabled = true
            sendButton.isEnabled = true
            sendButton.backgroundColor = UIColor(hex: "#3880BE")
    }
}
