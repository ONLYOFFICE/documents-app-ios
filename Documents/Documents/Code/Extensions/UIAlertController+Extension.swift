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
        view.tintColor = tintColor ?? Asset.Colors.brend.color
    }

    static func showError(in viewController: UIViewController, message: String, actions: [UIAlertAction]? = nil) {
        let alertController = UIAlertController.alert(
            NSLocalizedString("Error", comment: ""),
            message: message,
            actions: actions ?? []
        ).okable()
        viewController.present(alertController, animated: true, completion: nil)
    }

    static func showWarning(in viewController: UIViewController, message: String, actions: [UIAlertAction]? = nil) {
        let alertController = UIAlertController.alert(
            NSLocalizedString("Warning", comment: ""),
            message: message,
            actions: actions ?? []
        ).okable()
        viewController.present(alertController, animated: true, completion: nil)
    }

    static func showCancelableWarning(in viewController: UIViewController, message: String, actions: [UIAlertAction]? = nil) {
        let alertController = UIAlertController.alert(
            NSLocalizedString("Warning", comment: ""),
            message: message,
            actions: actions ?? []
        ).cancelable()
        viewController.present(alertController, animated: true, completion: nil)
    }
}
