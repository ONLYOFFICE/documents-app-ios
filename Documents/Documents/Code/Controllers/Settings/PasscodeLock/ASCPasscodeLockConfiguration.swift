//
//  ASCPasscodeLockConfiguration.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/22/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

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
    
    // MARK: - Lifecycle Methods
    
    init(repository: PasscodeRepositoryType) {
        self.repository = repository
    }
    
    init() {        
        self.repository = ASCUserDefaultsPasscodeRepository()
    }
}
