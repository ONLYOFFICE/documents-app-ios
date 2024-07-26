//
//  EnterPasscodeState.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

#if os(iOS)

    import Foundation

    public let PasscodeLockIncorrectPasscodeNotification = "passcode.lock.incorrect.passcode.notification"

    struct EnterPasscodeState: PasscodeLockStateType {
        let title: String
        var description: String
        let isCancellableAction: Bool
        var isTouchIDAllowed = true

        static let incorrectPasscodeAttemptsKey = "incorrectPasscodeAttempts"
        static var incorrectPasscodeAttempts: Int {
            get {
                return UserDefaults.standard.integer(forKey: incorrectPasscodeAttemptsKey)
            }
            set {
                UserDefaults.standard.set(newValue, forKey: incorrectPasscodeAttemptsKey)
            }
        }

        private var isNotificationSent = false

        init(allowCancellation: Bool = false) {
            isCancellableAction = allowCancellation
            title = localizedStringFor("PasscodeLockEnterTitle", comment: "Enter passcode title")
            description = " "
        }

        mutating func acceptPasscode(_ passcode: [String], fromLock lock: PasscodeLockType) {
            var lock = lock
            guard let currentPasscode = lock.repository.passcode else {
                return
            }

            var incorrectPasscodeAttempts = EnterPasscodeState.incorrectPasscodeAttempts
            if passcode == currentPasscode {
                lock.delegate?.passcodeLockDidSucceed(lock)
                incorrectPasscodeAttempts = 0
            } else {
                incorrectPasscodeAttempts += 1

                if incorrectPasscodeAttempts >= lock.configuration.maximumInccorectPasscodeAttempts {
                    postNotification()
                    incorrectPasscodeAttempts = 0
                }

                lock.state.description = localizedStringFor("Incorrect passcode entered", comment: "Entered wrong passcode")
                lock.delegate?.passcodeLockDidFail(lock)
            }

            EnterPasscodeState.incorrectPasscodeAttempts = incorrectPasscodeAttempts
        }

        fileprivate mutating func postNotification() {
            guard !isNotificationSent else { return }

            let center = NotificationCenter.default

            center.post(name: Notification.Name(rawValue: PasscodeLockIncorrectPasscodeNotification), object: nil)

            isNotificationSent = true
        }
    }

#endif
