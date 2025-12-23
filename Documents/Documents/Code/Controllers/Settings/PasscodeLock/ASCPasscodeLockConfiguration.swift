//
//  ASCPasscodeLockConfiguration.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/22/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import PasscodeLock
import UIKit

class ASCPasscodeLockConfiguration: PasscodeLockConfigurationType {
    // MARK: - Properties

    var touchIdReason: String?
    let repository: PasscodeRepositoryType
    let passcodeLength = 4
    var isTouchIDAllowed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.allowTouchId)
        }
        set {
            //
        }
    }

    let shouldRequestTouchIDImmediately = true
    let maximumInccorectPasscodeAttempts = -1
    var logoImage: UIImage? {
        Asset.Images.logoLarge.image
    }

    // MARK: - Lifecycle Methods

    init(repository: PasscodeRepositoryType) {
        self.repository = repository
    }

    init() {
        PasscodeLockStyles.backgroundColor = Asset.Colors.viewBackground.color
        PasscodeLockStyles.textColor = Asset.Colors.brend.color

        PasscodeLockStyles.overrideUserInterfaceStyle = AppThemeService.theme.overrideUserInterfaceStyle
        PasscodeLockStyles.SignPlaceholderViewStyles.activeColor = Asset.Colors.brend.color
        PasscodeLockStyles.SignPlaceholderViewStyles.errorColor = Asset.Colors.error.color
        PasscodeLockStyles.SignPlaceholderViewStyles.inactiveColor = Asset.Colors.viewBackground.color

        PasscodeLockStyles.SignButtonStyles.textColor = Asset.Colors.brend.color
        PasscodeLockStyles.SignButtonStyles.borderColor = Asset.Colors.brend.color
        PasscodeLockStyles.SignButtonStyles.highlightBackgroundColor = Asset.Colors.brend.color

        repository = ASCUserDefaultsPasscodeRepository()
    }
}
