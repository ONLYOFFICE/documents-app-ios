//
//  ASCBanner.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/31/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCBanner {
    static let shared = ASCBanner()

    private func showBanner(title: String, message: String, color: UIColor, textColor: UIColor) {
        guard let appWindow = UIApplication.shared.keyWindow else { return }
        var safeAreaTopOffset: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeAreaTopOffset = appWindow.safeAreaInsets.top
        }
        let bannerHeight: CGFloat = 45 + safeAreaTopOffset

        let view = UIView(frame: CGRect(x: 0, y: -bannerHeight, width: appWindow.frame.width, height: bannerHeight))
        view.backgroundColor = ASCConstants.Colors.red
        view.autoresizingMask = [.flexibleWidth]

        let titleLabel = UILabel(frame: CGRect(x: 0, y: bannerHeight - 40, width: view.bounds.width, height: 20))
        titleLabel.autoresizingMask = [.flexibleWidth]
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = textColor
        titleLabel.textAlignment = .center
        titleLabel.text = title
        view.addSubview(titleLabel)

        let messageLabel = UILabel(frame: CGRect(x: 0, y: bannerHeight - 20, width: view.bounds.width, height: 15))
        messageLabel.autoresizingMask = [.flexibleWidth]
        messageLabel.font = UIFont.systemFont(ofSize: 11)
        messageLabel.textColor = textColor
        messageLabel.textAlignment = .center
        messageLabel.text = message
        view.addSubview(messageLabel)

        delay(seconds: 0.4) {
            appWindow.addSubview(view)
            appWindow.bringSubviewToFront(view)

            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: .curveLinear, animations: {
                view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
            }) { completed in
                delay(seconds: 2) {
                    UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveLinear, animations: {
                        view.frame = CGRect(x: 0, y: -bannerHeight, width: view.frame.width, height: view.frame.height)
                    }) { completed in
                        view.removeFromSuperview()
                    }
                }
            }
        }
    }

    func showError(title: String, message: String) {
        showBanner(title: title, message: message, color: ASCConstants.Colors.red, textColor: .white)
    }
}
