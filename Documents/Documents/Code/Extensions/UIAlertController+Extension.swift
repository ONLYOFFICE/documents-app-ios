//
//  UIAlertController+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/31/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UIAlertController {
    convenience init(title: String?, message: String?, preferredStyle: UIAlertController.Style, tintColor: UIColor?) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        self.view.tintColor = tintColor ?? ASCConstants.Colors.brend
    }

    static func showError(in viewController: UIViewController, message: String) {
        let alertController = UIAlertController.alert(
            NSLocalizedString("Error", comment: ""),
            message: message,
            actions: []
            ).okable()
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    static func showWarning(in viewController: UIViewController, message: String) {
        let alertController = UIAlertController.alert(
            NSLocalizedString("Warning", comment: ""),
            message: message,
            actions: []
            ).okable()
        viewController.present(alertController, animated: true, completion: nil)
    }
}
