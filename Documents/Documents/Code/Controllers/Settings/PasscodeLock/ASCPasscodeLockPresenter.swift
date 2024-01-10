//
//  ASCPasscodeLockPresenter.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/22/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import PasscodeLock
import UIKit

class ASCPasscodeLockPresenter: PasscodeLockPresenter {
    // MARK: - Properties

    fileprivate let notificationCenter: NotificationCenter
    fileprivate let splashView: UIView

    var isFreshAppLaunch = true

    // MARK: - Lifecycle Methods

    init(mainWindow window: UIWindow?, configuration: PasscodeLockConfigurationType) {
        notificationCenter = NotificationCenter.default

        splashView = ASCPasscodeLockSplashView()

        // TIP: you can set your custom viewController that has added functionality in a custom .xib too
        let passcodeLockVC = PasscodeLockViewController(state: .enterPasscode, configuration: configuration)

        super.init(mainWindow: window, configuration: configuration, viewController: passcodeLockVC)

        // add notifications observers
        notificationCenter.addObserver(
            self,
            selector: #selector(ASCPasscodeLockPresenter.applicationDidLaunched),
            name: UIApplication.didFinishLaunchingNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(ASCPasscodeLockPresenter.applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(ASCPasscodeLockPresenter.applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        // remove all notfication observers
        notificationCenter.removeObserver(self)
    }

    @objc dynamic func applicationDidLaunched() {
        // start the Pin Lock presenter
        passcodeLockVC.successCallback = { [weak self] _ in

            // we can set isFreshAppLaunch to false
            self?.isFreshAppLaunch = false
        }

        PasscodeLockStyles.overrideUserInterfaceStyle = AppThemeService.theme.overrideUserInterfaceStyle
        presentPasscodeLock()
    }

    @objc dynamic func applicationDidEnterBackground() {
        PasscodeLockStyles.overrideUserInterfaceStyle = AppThemeService.theme.overrideUserInterfaceStyle

        // present PIN lock
        presentPasscodeLock()

        // add splashView for iOS app background swithcer
        let configuration = ASCPasscodeLockConfiguration()

        if configuration.repository.hasPasscode {
            addSplashView()
        }
    }

    @objc dynamic func applicationDidBecomeActive() {
        // remove splashView for iOS app background swithcer
        removeSplashView()
    }

    fileprivate func addSplashView() {
        // add splashView for iOS app background swithcer
        if isPasscodePresented {
            splashView.frame = passcodeLockVC.view.frame
            splashView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            passcodeLockVC.view.addSubview(splashView)
        } else {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                if let window = appDelegate.window {
                    splashView.frame = window.frame
                    splashView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                }
                appDelegate.window?.addSubview(splashView)
            }
        }
    }

    fileprivate func removeSplashView() {
        // remove splashView for iOS app background swithcer
        splashView.removeFromSuperview()
    }
}
