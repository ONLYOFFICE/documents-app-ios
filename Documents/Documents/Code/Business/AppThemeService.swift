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
        guard
            let sharedAppWindow = UIApplication.shared.delegate?.window
        else { return }

        switch AppThemeService.theme {
        case .automatic:
            sharedAppWindow?.overrideUserInterfaceStyle = .unspecified
        case .light:
            sharedAppWindow?.overrideUserInterfaceStyle = .light
        case .dark:
            sharedAppWindow?.overrideUserInterfaceStyle = .dark
        }
    }
}
