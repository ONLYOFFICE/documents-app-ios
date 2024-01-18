//
//  PasscodeLock.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

#if os(iOS)

    import Foundation
    import LocalAuthentication

    open class PasscodeLock: PasscodeLockType {
        open weak var delegate: PasscodeLockTypeDelegate?
        public let configuration: PasscodeLockConfigurationType

        open var repository: PasscodeRepositoryType {
            return configuration.repository
        }

        open var state: PasscodeLockStateType {
            return lockState
        }

        open var isTouchIDAllowed: Bool {
            return isTouchIDEnabled() && configuration.isTouchIDAllowed && lockState.isTouchIDAllowed
        }

        fileprivate var lockState: PasscodeLockStateType
        fileprivate lazy var passcode = [String]()

        public init(state: PasscodeLockStateType, configuration: PasscodeLockConfigurationType) {
            precondition(configuration.passcodeLength > 0, "Passcode length sould be greather than zero.")

            lockState = state
            self.configuration = configuration
        }

        open func addSign(_ sign: String) {
            passcode.append(sign)
            delegate?.passcodeLock(self, addedSignAtIndex: passcode.count - 1)

            if passcode.count >= configuration.passcodeLength {
                // handles "requires exclusive access" error at Swift 4
                var lockStateCopy = lockState
                lockStateCopy.acceptPasscode(passcode, fromLock: self)
                passcode.removeAll(keepingCapacity: true)
            }
        }

        open func removeSign() {
            guard passcode.count > 0 else { return }

            passcode.removeLast()
            delegate?.passcodeLock(self, removedSignAtIndex: passcode.count)
        }

        open func changeStateTo(_ state: PasscodeLockStateType) {
            lockState = state
            delegate?.passcodeLockDidChangeState(self)
        }

        open func authenticateWithBiometrics() {
            guard isTouchIDAllowed else { return }

            let context = LAContext()
            let reason: String

            if let configReason = configuration.touchIdReason {
                reason = configReason
            } else {
                reason = localizedStringFor("PasscodeLockTouchIDReason", comment: "TouchID authentication reason")
            }

            context.localizedFallbackTitle = localizedStringFor("PasscodeLockTouchIDButton", comment: "TouchID authentication fallback button")

            if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                if #available(iOS 11.0, *) {
                    if context.biometryType == .faceID {
                        context.localizedFallbackTitle = localizedStringFor("PasscodeLockFaceIDButton", comment: "FaceID authentication fallback button")
                    } else if context.biometryType == .touchID {
                        context.localizedFallbackTitle = localizedStringFor("PasscodeLockTouchIDButton", comment: "TouchID authentication fallback button")
                    }
                } else {
                    context.localizedFallbackTitle = localizedStringFor("PasscodeLockTouchIDButton", comment: "TouchID authentication fallback button")
                }

                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
                    self?.handleTouchIDResult(success)
                }
            }
        }

        fileprivate func handleTouchIDResult(_ success: Bool) {
            DispatchQueue.main.async {
                if success {
                    EnterPasscodeState.incorrectPasscodeAttempts = 0
                    self.delegate?.passcodeLockDidSucceed(self)
                }
            }
        }

        fileprivate func isTouchIDEnabled() -> Bool {
            return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        }
    }

#endif
