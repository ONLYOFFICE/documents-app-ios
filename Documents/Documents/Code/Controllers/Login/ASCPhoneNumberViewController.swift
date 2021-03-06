//
//  ASCPhoneNumberViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/10/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import PhoneNumberKit
import MBProgressHUD

class ASCPhoneNumberViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties

    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var countryCodeField: UITextField!
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var numberField: PhoneNumberTextField!

    var options: [String: Any] = [:]
    var completeon: ASCSignInComplateHandler?

    private let phoneNumberKit = PhoneNumberKit()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.phone {
            if UIDevice.greatOfInches(.inches47) {
                topConstraint.constant = 40
            } else {
                topConstraint.constant = 10
            }
        }
        
        for field in [countryCodeField, codeField, numberField] {
            field?.delegate = self
            field?.underline(color: ASCConstants.Colors.lightGrey)
        }
        
        if let countryCode = Locale.current.regionCode {
            if let code = phoneNumberKit.countryCode(for: countryCode) {
                codeField.text = "+\(code)"
            }
            
            if let countryName = Locale.current.localizedString(forRegionCode: countryCode) {
                countryCodeField.text = countryName
            }
        }
        
        codeField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
        
        numberField?.becomeFirstResponder()
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }
    
    // MARK: - UITextField Delegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == countryCodeField {
            performSegue(withIdentifier: "sequeShowCountry", sender: countryCodeField)
            return false
        }
        
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == codeField {
            if let stringCode = textField.text?.trim().replacingOccurrences(of: "+", with: ""), let intCode = UInt64(stringCode) {
                if let regionCode = phoneNumberKit.mainCountry(forCode: intCode) {
                    if let countryName = Locale.current.localizedString(forRegionCode: regionCode) {
                        countryCodeField.text = countryName
                        return
                    }
                }
            }
            countryCodeField.text = NSLocalizedString("Invalid Country Code", comment: "")
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == codeField {
            guard let text = textField.text else { return true }
            let newLength = text.count + string.count - range.length
            
            var allowedCharacters = CharacterSet.decimalDigits
            allowedCharacters.insert(charactersIn: "+")
            allowedCharacters = allowedCharacters.inverted
            let compSepByCharInSet = string.components(separatedBy: allowedCharacters)
            let numberFiltered = compSepByCharInSet.joined(separator: "")
            
            return newLength <= 4 && string == numberFiltered
        }
        
        return true
    }
    
    // MARK: - Actions
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        var isValidNumber = false
        var phoneNumber: PhoneNumber!

        if  let stringCode = codeField.text?.trim().replacingOccurrences(of: "+", with: ""),
            let intCode = UInt64(stringCode),
            let regionCode = phoneNumberKit.mainCountry(forCode: intCode)
        {
            do {
                phoneNumber = try phoneNumberKit.parse("\(codeField.text!)\(numberField.text!)", withRegion: regionCode)
                isValidNumber = true
            } catch let error {
                log.error(error)
                isValidNumber = false
            }
        }
        
        if isValidNumber {
            let phoneNumberE164   = phoneNumberKit.format(phoneNumber, toType: .e164)
            let phoneNumberNormal = phoneNumberKit.format(phoneNumber, toType: .national)
            
            options["phoneNoise"]  = phoneNumberNormal
            options["mobilePhone"] = phoneNumberE164
            
            let hud = MBProgressHUD.showTopMost()
            
            ASCOnlyOfficeApi.post(ASCOnlyOfficeApi.apiAuthenticationPhone, parameters: options) { [weak self] (results, error, response) in
                hud?.hide(animated: true)

                guard let strongSelf = self else { return }

                if error != nil {
                    UIAlertController.showError(in: strongSelf, message: ASCOnlyOfficeApi.errorMessage(by: response!))
                    log.error(error!)
                } else {
                    if let navigationController = strongSelf.navigationController {
                        ASCSignInController.shared.presentSmsCode(in: navigationController, options: strongSelf.options, completion: strongSelf.completeon)
                    }
                }
            }
        } else {
            codeField.shake()
            numberField.shake()
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sequeShowCountry" {
            if let countryCodeController = segue.destination as? ASCCountryCodeViewController {
                countryCodeController.selectCountry = { (country, code) in
                    self.countryCodeField.text = country
                    self.codeField.text = "+\(code)"
                }
            }
        }
    }
}
