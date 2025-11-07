//
//  PasscodeLockPresenter.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/29/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

#if os(iOS)

    import UIKit

    open class PasscodeLockPresenter {
        private var mainWindow: UIWindow?

        private lazy var passcodeLockWindow: UIWindow? = {
            guard let windowScene = getFirstForegroundScene() else { return nil }
            let window = UIWindow(windowScene: windowScene)
            window.overrideUserInterfaceStyle = PasscodeLockStyles.overrideUserInterfaceStyle
            window.windowLevel = UIWindow.Level(rawValue: 0)
            window.makeKeyAndVisible()

            return window
        }()

        private let passcodeConfiguration: PasscodeLockConfigurationType
        open var isPasscodePresented = false
        open var hasPasscode = false

        public let passcodeLockVC: PasscodeLockViewController

        public init(mainWindow window: UIWindow?, configuration: PasscodeLockConfigurationType, viewController: PasscodeLockViewController) {
            mainWindow = window
            mainWindow?.windowLevel = UIWindow.Level(rawValue: 1)
            passcodeConfiguration = configuration
            hasPasscode = configuration.repository.hasPasscode

            passcodeLockVC = viewController
        }

        public convenience init(mainWindow window: UIWindow?, configuration: PasscodeLockConfigurationType) {
            let passcodeLockVC = PasscodeLockViewController(state: .enterPasscode, configuration: configuration)

            self.init(mainWindow: window, configuration: configuration, viewController: passcodeLockVC)
        }

        // HACK: below function that handles not presenting the keyboard in case Passcode is presented
        //       is a smell in the code that had to be introduced for iOS9 where Apple decided to move the keyboard
        //       in a UIRemoteKeyboardWindow.
        //       This doesn't allow our Passcode Lock window to move on top of keyboard.
        //       Setting a higher windowLevel to our window or even trying to change keyboards'
        //       windowLevel has been tried without luck.
        //
        //       Revise in a later version and remove the hack if not needed
        func toggleKeyboardVisibility(hide: Bool) {
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }

            if let keyboardWindow = windows.last,
               keyboardWindow.description.hasPrefix("<UIRemoteKeyboardWindow")
            {
                keyboardWindow.alpha = hide ? 0.0 : 1.0
            } else {
                windows
                    .first { $0.isKeyWindow }?
                    .endEditing(true)
            }
        }

        open func presentPasscodeLock() {
            guard passcodeConfiguration.repository.hasPasscode else { return }
            guard !isPasscodePresented else { return }

            isPasscodePresented = true
            passcodeLockWindow?.windowLevel = UIWindow.Level.statusBar - 1
            passcodeLockWindow?.overrideUserInterfaceStyle = PasscodeLockStyles.overrideUserInterfaceStyle

            toggleKeyboardVisibility(hide: true)

            let userDismissCompletionCallback = passcodeLockVC.dismissCompletionCallback

            passcodeLockVC.dismissCompletionCallback = { [weak self] in
                userDismissCompletionCallback?()

                self?.dismissPasscodeLock()
            }

            passcodeLockWindow?.rootViewController = passcodeLockVC
        }

        open func dismissPasscodeLock(animated: Bool = true) {
            isPasscodePresented = false
            mainWindow?.windowLevel = UIWindow.Level(rawValue: 1)
            mainWindow?.makeKeyAndVisible()

            if animated {
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: 0,
                    options: [.curveEaseInOut],
                    animations: { [weak self] in
                        self?.passcodeLockWindow?.alpha = 0
                    },
                    completion: { [weak self] _ in
                        self?.passcodeLockWindow?.windowLevel = UIWindow.Level(rawValue: 0)
                        self?.passcodeLockWindow?.rootViewController = nil
                        self?.passcodeLockWindow?.alpha = 1
                        self?.toggleKeyboardVisibility(hide: false)
                    }
                )
            } else {
                passcodeLockWindow?.windowLevel = UIWindow.Level(rawValue: 0)
                passcodeLockWindow?.rootViewController = nil
                toggleKeyboardVisibility(hide: false)
            }
        }

        @available(iOS 13.0, tvOS 13.0, *)
        private func getFirstForegroundScene() -> UIWindowScene? {
            let connectedScenes = UIApplication.shared.connectedScenes
            if let windowActiveScene = connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                return windowActiveScene
            } else if let windowInactiveScene = connectedScenes.first(where: { $0.activationState == .foregroundInactive }) as? UIWindowScene {
                return windowInactiveScene
            } else {
                return connectedScenes.first as? UIWindowScene
            }
        }

//        private func keyWindow() -> UIWindow? {
//            if #available(iOS 13.0, *) {
//                for scene in UIApplication.shared.connectedScenes {
//                    guard let windowScene = scene as? UIWindowScene else {
//                        continue
//                    }
//                    if windowScene.windows.isEmpty {
//                        continue
//                    }
//                    guard let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
//                        continue
//                    }
//                    return window
//                }
//                return nil
//            } else {
//                return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
//            }
//        }
    }

#endif
