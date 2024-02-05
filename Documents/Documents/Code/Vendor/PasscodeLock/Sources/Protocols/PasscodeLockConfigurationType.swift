//
//  PasscodeLockConfigurationType.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

#if os(iOS)

    import Foundation

    public protocol PasscodeLockConfigurationType {
        var repository: PasscodeRepositoryType { get }
        var passcodeLength: Int { get }
        var isTouchIDAllowed: Bool { get set }
        var shouldRequestTouchIDImmediately: Bool { get }
        var touchIdReason: String? { get set }
        var maximumInccorectPasscodeAttempts: Int { get }
    }

#endif
