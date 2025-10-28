//
//  AppThemeService.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.05.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

enum AppThemeService {
    static var theme: AppTheme {
        get { AppTheme(rawValue: UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.appTheme) ?? "") ?? .automatic }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: ASCConstants.SettingsKeys.appTheme)
            AppThemeService.update()
        }
    }

    private static func update() {
        switch AppThemeService.theme {
        case .automatic:
            UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .unspecified
        case .light:
            UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .light
        case .dark:
            UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .dark
        }
    }
}
