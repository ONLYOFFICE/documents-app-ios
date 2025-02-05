//
//  ASCSMSCodeViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/11/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import IQKeyboardManagerSwift
import IQKeyboardToolbarManager
import MBProgressHUD
import UIKit

class ASCSMSCodeViewController: ASCBaseViewController {
    override class var storyboard: Storyboard { return Storyboard.login }

    // MARK: - Properties

    @IBOutlet var codeField: UITextField!
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var sendSmsLabel: UILabel!

    private let codeLength: Int = 6
    var phoneNumber: String = "" {
        didSet {
            infoLabel?.text = String(format: NSLocalizedString("We have sent you an SMS with a code to the number %@", comment: ""), phoneNumber)
        }
    }

    var request: OnlyofficeAuthRequest?
    var completeon: ASCSignInComplateHandler?

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        codeField?.delegate = self
        codeField?.underline(color: ASCConstants.Colors.lightGrey)
        codeField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunction))
        sendSmsLabel.isUserInteractionEnabled = true
        sendSmsLabel.addGestureRecognizer(tapGesture)

        if let phoneNoise = request?.phoneNoise {
            infoLabel?.text = String(format: NSLocalizedString("We have sent you an SMS with a code to the number %@", comment: ""), phoneNoise)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()

        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardToolbarManager.shared.toolbarConfiguration.placeholderConfiguration.showPlaceholder = false
        IQKeyboardToolbarManager.shared.toolbarConfiguration.useTextInputViewTintColor = true

        codeField?.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        IQKeyboardManager.shared.isEnabled = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }

    @objc func tapFunction(sender: UITapGestureRecognizer) {
        sendSmsLabel.alpha = 0.5

        UIView.animate(withDuration: 0.6) {
            self.sendSmsLabel.alpha = 1
        }

        resendCode()
    }

    private func resendCode() {
        let hud = MBProgressHUD.showTopMost()

        guard let request = request else { return }

        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Auth.sendCode, request.toJSON()) { response, error in
            hud?.hide(animated: true)

            if let error = error {
                UIAlertController.showError(in: self, message: error.localizedDescription)
                log.error(error)
            }
        }
    }

    private func loginByCode(request: OnlyofficeAuthRequest, completion: ASCSignInComplateHandler?) {
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

        ASCSignInController.shared.login(by: request) { success in
            if success {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: .twoSecondsDelay)
            } else {
                hud?.hide(animated: true)
            }
            completion?(success)
        }
    }

    private func login(with code: String) {
        guard let request = request else { return }
        request.code = code
        loginByCode(request: request, completion: completeon)
    }
}

// MARK: - UITextField Delegate

extension ASCSMSCodeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.count ?? 0

        if range.length + range.location > currentCharacterCount {
            return false
        }

        let newLength = currentCharacterCount + string.count - range.length

        return newLength <= codeLength
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == codeField, let fieldText = textField.text {
            let code = fieldText.trimmed.substring(to: codeLength)

            if code.length == codeLength {
                login(with: code)
            }
        }
    }
}
