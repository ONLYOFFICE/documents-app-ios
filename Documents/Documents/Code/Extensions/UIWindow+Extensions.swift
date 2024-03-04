//
//  UIWindow+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 01.12.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

public extension UIWindow {
    static var keyWindow: UIWindow? {
        UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }
    }
}
