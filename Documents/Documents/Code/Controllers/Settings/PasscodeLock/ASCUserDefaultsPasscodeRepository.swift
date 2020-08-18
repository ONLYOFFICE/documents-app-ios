//
//  ASCUserDefaultsPasscodeRepository.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/22/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCUserDefaultsPasscodeRepository: PasscodeRepositoryType {
    
    // MARK: - Properties
    
    fileprivate let passcodeKey = "passcode.lock.passcode"
    fileprivate lazy var defaults: UserDefaults = {
        return UserDefaults.standard
    }()
    
    var hasPasscode: Bool {
        if passcode != nil {
            return true
        }
        
        return false
    }
    
    var passcode: [String]? {
        return defaults.value(forKey: passcodeKey) as? [String] ?? nil
    }
    
    // MARK: - Public
    
    func savePasscode(_ passcode: [String]) {
        defaults.set(passcode, forKey: passcodeKey)
        defaults.synchronize()
    }
    
    func deletePasscode() {
        defaults.removeObject(forKey: passcodeKey)
        defaults.synchronize()
    }
}
