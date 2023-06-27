//
//  AppTheme.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.05.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

enum AppTheme: String, CaseIterable {
    case automatic, light, dark

    var description: String {
        switch self {
        case .automatic:
            return NSLocalizedString("Same as system", comment: "")
        case .light:
            return NSLocalizedString("Light", comment: "")
        case .dark:
            return NSLocalizedString("Dark", comment: "")
        }
    }

    var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .automatic:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
