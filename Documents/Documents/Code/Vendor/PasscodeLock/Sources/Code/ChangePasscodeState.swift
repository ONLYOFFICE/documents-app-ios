//
//  ChangePasscodeState.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

#if os(iOS)

    import Foundation

    struct ChangePasscodeState: PasscodeLockStateType {
        let title: String
        var description: String
        let isCancellableAction = true
        var isTouchIDAllowed = false

        init() {
            title = localizedStringFor("PasscodeLockChangeTitle", comment: "Change passcode title")
            description = " "
        }

        func acceptPasscode(_ passcode: [String], fromLock lock: PasscodeLockType) {
            var lock = lock
            guard let currentPasscode = lock.repository.passcode else {
                return
            }

            if passcode == currentPasscode {
                let nextState = SetPasscodeState()
                lock.changeStateTo(nextState)
            } else {
                lock.state.description = localizedStringFor("Incorrect passcode entered", comment: "Entered wrong passcode")
                lock.delegate?.passcodeLockDidFail(lock)
            }
        }
    }

#endif
