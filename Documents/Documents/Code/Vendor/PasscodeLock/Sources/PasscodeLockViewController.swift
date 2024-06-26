//
//  PasscodeLockViewController.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

#if os(iOS)

    import LocalAuthentication
    import UIKit

    open class PasscodeLockViewController: UIViewController, PasscodeLockTypeDelegate {
        public enum LockState {
            case enterPasscode
            case setPasscode
            case changePasscode
            case removePasscode

            func getState() -> PasscodeLockStateType {
                switch self {
                case .enterPasscode: return EnterPasscodeState()
                case .setPasscode: return SetPasscodeState()
                case .changePasscode: return ChangePasscodeState()
                case .removePasscode: return EnterPasscodeState(allowCancellation: true)
                }
            }
        }

        @IBOutlet open var titleLabel: UILabel?
        @IBOutlet open var descriptionLabel: UILabel?
        @IBOutlet open var placeholders: [PasscodeSignPlaceholderView] = [PasscodeSignPlaceholderView]()
        @IBOutlet open var cancelButton: UIButton?
        @IBOutlet open var deleteSignButton: UIButton?
        @IBOutlet open var touchIDButton: UIButton?
        @IBOutlet open var placeholdersX: NSLayoutConstraint?

        open var successCallback: ((_ lock: PasscodeLockType) -> Void)?
        open var dismissCompletionCallback: (() -> Void)?
        open var animateOnDismiss: Bool

        let passcodeConfiguration: PasscodeLockConfigurationType
        var passcodeLock: PasscodeLockType
        var isPlaceholdersAnimationCompleted = true

        fileprivate var shouldTryToAuthenticateWithBiometrics = true

        // MARK: - Initializers

        public init(state: PasscodeLockStateType, configuration: PasscodeLockConfigurationType, animateOnDismiss: Bool = true, nibName: String = "PasscodeLockView", bundle: Bundle? = nil) {
            self.animateOnDismiss = animateOnDismiss

            passcodeConfiguration = configuration
            passcodeLock = PasscodeLock(state: state, configuration: configuration)

            let bundleToUse = bundle ?? bundleForResource(nibName, ofType: "nib")

            super.init(nibName: nibName, bundle: bundleToUse)

            view.backgroundColor = PasscodeLockStyles.backgroundColor
            cancelButton?.setTitleColor(PasscodeLockStyles.textColor, for: .normal)
            deleteSignButton?.setTitleColor(PasscodeLockStyles.textColor, for: .normal)
            touchIDButton?.setTitleColor(PasscodeLockStyles.textColor, for: .normal)

            passcodeLock.delegate = self
        }

        public convenience init(state: LockState, configuration: PasscodeLockConfigurationType, animateOnDismiss: Bool = true) {
            self.init(state: state.getState(), configuration: configuration, animateOnDismiss: animateOnDismiss)
        }

        @available(*, unavailable)
        public required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit {
            clearEvents()
        }

        // MARK: - View

        override open func viewDidLoad() {
            super.viewDidLoad()

            deleteSignButton?.isEnabled = false

            if false, !UIAccessibility.isReduceTransparencyEnabled {
                view.backgroundColor = .clear

                let blur = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
                blur.frame = view.bounds
                blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                view.insertSubview(blur, at: 0)
            }

            setupEvents()
        }

        override open func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            updatePasscodeView()
        }

        override open func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            if shouldTryToAuthenticateWithBiometrics, passcodeConfiguration.shouldRequestTouchIDImmediately {
                authenticateWithBiometrics()
            }
        }

        override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : [.portrait, .landscape]
        }

        override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
            return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : super.preferredInterfaceOrientationForPresentation
        }

        func updatePasscodeView() {
            titleLabel?.text = passcodeLock.state.title
            descriptionLabel?.text = passcodeLock.state.description
            cancelButton?.isHidden = !passcodeLock.state.isCancellableAction
            touchIDButton?.isHidden = !passcodeLock.isTouchIDAllowed

            let context = LAContext()
            if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                if #available(iOS 11.0, *) {
                    if context.biometryType == .faceID {
                        touchIDButton?.setTitle(localizedStringFor("Use Face ID", comment: "Button title"), for: .normal)
                    } else if context.biometryType == .touchID {
                        touchIDButton?.setTitle(localizedStringFor("Use Touch ID", comment: "Button title"), for: .normal)
                    }
                } else {
                    touchIDButton?.setTitle(localizedStringFor("Use Touch ID", comment: "Button title"), for: .normal)
                }
            }
        }

        // MARK: - Events

        fileprivate func setupEvents() {
            NotificationCenter.default.addObserver(self, selector: #selector(PasscodeLockViewController.appWillEnterForegroundHandler(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(PasscodeLockViewController.appDidEnterBackgroundHandler(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }

        fileprivate func clearEvents() {
            NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        }

        @objc open func appWillEnterForegroundHandler(_ notification: Notification) {
            if passcodeConfiguration.shouldRequestTouchIDImmediately {
                authenticateWithBiometrics()
            }
        }

        @objc open func appDidEnterBackgroundHandler(_ notification: Notification) {
            shouldTryToAuthenticateWithBiometrics = false
        }

        // MARK: - Actions

        @IBAction func passcodeSignButtonTap(_ sender: PasscodeSignButton) {
            guard isPlaceholdersAnimationCompleted else { return }

            passcodeLock.addSign(sender.passcodeSign)
        }

        @IBAction func cancelButtonTap(_ sender: UIButton) {
            dismissPasscodeLock(passcodeLock)
        }

        @IBAction func deleteSignButtonTap(_ sender: UIButton) {
            passcodeLock.removeSign()
        }

        @IBAction func touchIDButtonTap(_ sender: UIButton) {
            passcodeLock.authenticateWithBiometrics()
        }

        open func authenticateWithBiometrics() {
            guard passcodeConfiguration.repository.hasPasscode else { return }

            if passcodeLock.isTouchIDAllowed {
                passcodeLock.authenticateWithBiometrics()
            }
        }

        func dismissPasscodeLock(_ lock: PasscodeLockType, completionHandler: (() -> Void)? = nil) {
            // if presented as modal
            if presentingViewController?.presentedViewController == self {
                dismiss(animated: animateOnDismiss, completion: { [weak self] in

                    self?.dismissCompletionCallback?()

                    completionHandler?()
                })

                return

                        // if pushed in a navigation controller
            } else if navigationController != nil {
                navigationController?.popViewController(animated: animateOnDismiss)
            }

            dismissCompletionCallback?()

            completionHandler?()
        }

        // MARK: - Animations

        func animateWrongPassword() {
            deleteSignButton?.isEnabled = false
            isPlaceholdersAnimationCompleted = false

            animatePlaceholders(placeholders, toState: .error)

            placeholdersX?.constant = -40
            view.layoutIfNeeded()

            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.2,
                initialSpringVelocity: 0,
                options: [],
                animations: {
                    self.placeholdersX?.constant = 0
                    self.view.layoutIfNeeded()
                },
                completion: { completed in

                    self.isPlaceholdersAnimationCompleted = true
                    self.animatePlaceholders(self.placeholders, toState: .inactive)
                }
            )
        }

        func animatePlaceholders(_ placeholders: [PasscodeSignPlaceholderView], toState state: PasscodeSignPlaceholderView.State) {
            for placeholder in placeholders {
                placeholder.animateState(state)
            }
        }

        fileprivate func animatePlacehodlerAtIndex(_ index: Int, toState state: PasscodeSignPlaceholderView.State) {
            guard index < placeholders.count, index >= 0 else { return }

            placeholders[index].animateState(state)
        }

        // MARK: - PasscodeLockDelegate

        open func passcodeLockDidSucceed(_ lock: PasscodeLockType) {
            deleteSignButton?.isEnabled = true
            animatePlaceholders(placeholders, toState: .inactive)
            dismissPasscodeLock(lock, completionHandler: { [weak self] in
                self?.successCallback?(lock)
            })
        }

        open func passcodeLockDidFail(_ lock: PasscodeLockType) {
            animateWrongPassword()
        }

        open func passcodeLockDidChangeState(_ lock: PasscodeLockType) {
            updatePasscodeView()
            animatePlaceholders(placeholders, toState: .inactive)
            deleteSignButton?.isEnabled = false
        }

        open func passcodeLock(_ lock: PasscodeLockType, addedSignAtIndex index: Int) {
            animatePlacehodlerAtIndex(index, toState: .active)
            deleteSignButton?.isEnabled = true
        }

        open func passcodeLock(_ lock: PasscodeLockType, removedSignAtIndex index: Int) {
            animatePlacehodlerAtIndex(index, toState: .inactive)

            if index == 0 {
                deleteSignButton?.isEnabled = false
            }
        }
    }

#endif
