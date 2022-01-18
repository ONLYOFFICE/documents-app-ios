//
//  ASC2FAPageController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 15/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit
//import SwiftEntryKit

class ASC2FAPageController: UIViewController {
    static let identifier = String(describing: ASC2FAPageController.self)

    // MARK: - Properties

    var secret: String?
    var request: OnlyofficeAuthRequest?
    var completeon: ASCSignInComplateHandler?

    @IBOutlet weak var secretField: UITextField!

    fileprivate lazy var tostCopyView: UIView = {
        let height: CGFloat = 50
        let title = NSLocalizedString("Text copied", comment: "Notification title")

        let label = UILabel()
        label.textAlignment = .center
        label.text = title
        label.font = UIFont.systemFont(ofSize: 17)
        label.frame = CGRect(x: 30, y: (height - 20) * 0.5, width: label.intrinsicContentSize.width, height: 20)

        if #available(iOS 13.0, *) {
            $0.backgroundColor = .tertiarySystemBackground
        } else {
            $0.backgroundColor = .white
        }
        $0.frame = CGRect(x: 0, y: 0, width: label.frame.width + 60, height: height)
        $0.layer.cornerRadius = height * 0.5
        $0.layer.shadowOpacity = 0.25
        $0.layer.shadowColor = UIColor.lightGray.cgColor
        $0.layer.shadowOffset = CGSize(width: 0, height: 10)
        $0.layer.shadowRadius = 25
        $0.layer.borderWidth = 0.5
        $0.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor

        $0.addSubview(label)

        return $0
    }(UIView(frame: .zero))

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        if let secret = secret {
            secretField?.text = secret.split(by: 4).joined(separator: " ")
        }

        secretField?.underline(color: Asset.Colors.brend.color)
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
    
    // MARK: - Actions

    @IBAction func openAuthApp(_ sender: UIButton) {
        // otpauth://TYPE/LABEL?PARAMETERS
        // More info:  https://github.com/google/google-authenticator/tree/master/mobile/ios

        guard
            let request = request,
            let urlGoogleAuth = URL(string: ASCConstants.Urls.appStoreGoogleAuth)
        else { return }

        let userName = request.userName
        let portal = request.portal
        let appName = ASCConstants.Name.appNameShort

        var urlComponents = URLComponents()
        urlComponents.scheme = "otpauth"
        urlComponents.host = "totp"
        urlComponents.path = "/" + (userName ?? portal ?? appName)
        urlComponents.queryItems = [
            URLQueryItem(name: "secret", value: secret ?? ""),
            URLQueryItem(name: "issuer", value: "\(appName) - \(portal ?? "")")
        ]

        do {
            let url = try urlComponents.asURL()

            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.open(urlGoogleAuth, options: [:], completionHandler: nil)
            }
        } catch {
            UIApplication.shared.open(urlGoogleAuth, options: [:], completionHandler: nil)
        }
    }
    @IBAction func onCopySecret(_ sender: UIButton) {
        guard
            let field = secretField,
            let secret = secret
        else { return }

        // Copy secret to Pasteboard
        UIPasteboard.general.string = secret

        // Display hint
        tostCopyView.alpha = 0

        view.layer.removeAllAnimations()
        tostCopyView.layer.removeAllAnimations()

        tostCopyView.removeFromSuperview()
        view.addSubview(tostCopyView)

        let hintStartCener = CGPoint(x: field.frame.midX, y: field.frame.midY - 30)
        tostCopyView.center = hintStartCener

        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            var newCenter = hintStartCener
            newCenter.y -= 20

            self?.tostCopyView.alpha = 1
            self?.tostCopyView.center = newCenter
        }, completion: { [weak self] finished in
            UIView.animate(withDuration: 0.25, delay: 2.0, options: .curveEaseOut, animations: { [weak self] in
                var newCenter = hintStartCener
                newCenter.y -= 40

                self?.tostCopyView.alpha = 0
                self?.tostCopyView.center = newCenter
            }, completion: { [weak self] finished in
                self?.tostCopyView.removeFromSuperview()
            })
        })
    }
}
