//
//  UIWindowExtensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 01.12.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

public extension UIWindow {
    static var keyWindow: UIWindow? {
        UIApplication.shared
            // Get connected scenes
            .connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
            // Get its associated windows
            .flatMap { $0 as? UIWindowScene }?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
}
