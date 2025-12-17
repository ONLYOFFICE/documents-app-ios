//
//  ASCStyles.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/31/18.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ASCStyles {
    static let initialize: Void = {
        //
    }()

    static var barFixedSpace: UIBarButtonItem = {
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = UIDevice.phone ? -10 : 0
        return spacer
    }()

    static func createBarButton(image: UIImage?, target: Any?, action: Selector, color: UIColor? = nil) -> UIBarButtonItem {
        let defaultColor = ASCCommon.isiOS26 ? .label : Asset.Colors.brend.color
        let buttonSize = UIDevice.phone
            ? CGSize(width: 35, height: 30)
            : CGSize(width: 50, height: 35)
        let button: UIButton = UIButton(type: .custom)
        if let image {
            button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        button.addTarget(target, action: action, for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: buttonSize.width, height: buttonSize.height)
        button.tintColor = color ?? defaultColor

        return UIBarButtonItem(customView: button)
    }

    static func createBarButton(title: String, target: Any?, action: Selector) -> UIBarButtonItem {
        return UIBarButtonItem(title: title, style: .plain, target: target, action: action)
    }

    static func createBarButton(title: String, menu: UIMenu?) -> UIBarButtonItem {
        return UIBarButtonItem(title: title, image: nil, primaryAction: nil, menu: menu)
    }
}
