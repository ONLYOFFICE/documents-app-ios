//
//  ASC2FACodeViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit
import MBProgressHUD
import IQKeyboardManagerSwift

class ASC2FACodeViewController: ASCBaseViewController {
    static let identifier = String(describing: ASC2FACodeViewController.self)
    
    class override var storyboard: Storyboard { return Storyboard.login }

    // MARK: - Properties

    var code: String?
    var request: OnlyofficeAuthRequest?
    var completeon: ASCSignInComplateHandler?

    private let codeLength: Int = 6

    // MARK: - Outlets
    
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var helpLabel: UILabel!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        if let code = code {
            codeField?.text = code
        }

        codeField?.delegate = self
        codeField?.underline(color: Asset.Colors.brend.color)
        codeField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunction))
        helpLabel?.isUserInteractionEnabled = true
        helpLabel?.addGestureRecognizer(tapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        IQKeyboardManager.shared.shouldShowToolbarPlaceholder = false
        IQKeyboardManager.shared.shouldToolbarUsesTextFieldTintColor = true

        if let _ = helpLabel {
            codeField?.becomeFirstResponder()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkPastboard()
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
    
    @objc func tapFunction(sender: UITapGestureRecognizer) {
        helpLabel?.alpha = 0.5

        UIView.animate(withDuration: 0.6) {
            self.helpLabel?.alpha = 1
        }

        if let helpUrl = URL(string: ASCConstants.Urls.help2authByApp) {
            UIApplication.shared.open(helpUrl, options: [:], completionHandler: nil)
        }
    }

    private func checkPastboard() {
        if let pasteBoardString = UIPasteboard.general.string {
            if pasteBoardString.count == codeLength, pasteBoardString.isDigits {
                codeField?.text = pasteBoardString
                login(with: pasteBoardString)
            }
        }
    }

    private func loginByCode(request: OnlyofficeAuthRequest, completion: ASCSignInComplateHandler?) {
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

        ASCSignInController.shared.login(by: request) { success in
            if success {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: 2)
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

extension ASC2FACodeViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = codeField.text?.count ?? 0

        if (range.length + range.location > currentCharacterCount){
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
