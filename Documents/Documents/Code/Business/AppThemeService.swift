//
//  AppThemeService.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.05.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

enum AppThemeService {
    static func set(theme: AppTheme) {
        ASCAppSettings.appTheme = theme
        AppThemeService.check()
    }

    static func check() {
        guard
            let sharedAppWindow = UIApplication.shared.delegate?.window
        else { return }

        switch ASCAppSettings.appTheme {
        case .automatic:
            sharedAppWindow?.overrideUserInterfaceStyle = .unspecified
        case .light:
            sharedAppWindow?.overrideUserInterfaceStyle = .light
        case .dark:
            sharedAppWindow?.overrideUserInterfaceStyle = .dark
        }
    }
}
