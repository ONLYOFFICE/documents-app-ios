//
//  ASCSceneDelegate.swift
//  Documents
//
//  Created by Migration on 19/08/2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import CoreServices
import CoreSpotlight
import GoogleSignIn
import PasscodeLock
import SwiftyDropbox
import UIKit

class ASCSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = AppThemeService.theme.overrideUserInterfaceStyle
        window?.rootViewController = ASCRootViewController.instance()
        window?.makeKeyAndVisible()

        // Initialize PasscodeLock presenter
        initPasscodeLock(for: window)

        if passcodeLockPresenter.hasPasscode {
            passcodeLockPresenter.passcodeLockVC.dismissCompletionCallback = { [weak self] in
                self?.handleConnectionOptions(connectionOptions)
                self?.passcodeLockPresenter.dismissPasscodeLock(animated: true)
            }
        } else {
            handleConnectionOptions(connectionOptions)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        NotificationCenter.default.post(name: ASCConstants.Notifications.appDidBecomeActive, object: nil)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    // MARK: - URL Handling

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        if passcodeLockPresenter.hasPasscode {
            passcodeLockPresenter.passcodeLockVC.dismissCompletionCallback = { [weak self] in
                self?.handleUrl(url)
                self?.passcodeLockPresenter.dismissPasscodeLock(animated: true)
            }
        } else {
            handleUrl(url)
        }
    }

    func handleConnectionOptions(_ connectionOptions: UIScene.ConnectionOptions) {
        // Handle URL context if app was launched via URL
        if let urlContext = connectionOptions.urlContexts.first {
            handleUrl(urlContext.url)
        }

        // Handle shortcut item if app was launched via shortcut
        if let shortcutItem = connectionOptions.shortcutItem {
            handleShortcut(shortcutItem)
        }

        // Handle user activity if app was launched via user activity
        if let userActivity = connectionOptions.userActivities.first {
            handleUserActivity(userActivity)
        }
    }

    private func handleUrl(_ url: URL) {
        if let bundleTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            for urlType in bundleTypes {
                if let service = urlType["CFBundleURLName"] as? String,
                   let schemes = urlType["CFBundleURLSchemes"] as? [String],
                   let scheme = schemes.last
                {
                    if let _ = url.scheme?.range(of: scheme, options: .caseInsensitive) {
                        if service == "facebook" {
                            ASCFacebookSignInController.application(open: url)
                        } else if service == "google" {
                            _ = GIDSignIn.sharedInstance.handle(url)
                        } else if service == "dropbox" {
                            DropboxClientsManager.handleRedirectURL(
                                url,
                                includeBackgroundClient: false,
                                completion: ASCDropboxSDKWrapper.shared.handleOAuthRedirect
                            )
                        } else if service == "oodocuments" {
                            ASCViewControllerManager.shared.route(by: url)
                        }
                    }
                }
            }
        }

        if url.isFileURL {
            ASCViewControllerManager.shared.route(by: url)
        }
    }

    // MARK: - User Activity Handling

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleUserActivity(userActivity)
    }

    private func handleUserActivity(_ userActivity: NSUserActivity) {
        if userActivity.activityType == CSSearchableItemActionType,
           let info = userActivity.userInfo,
           let selectedIdentifier = info[CSSearchableItemActivityIdentifier] as? String
        {
            log.debug("Selected Identifier: \(selectedIdentifier)")
        }
    }

    // MARK: - Shortcut Handling

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }

    @discardableResult
    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        switch shortcutItem.type {
        case ASCConstants.Shortcuts.newDocument:
            delay(seconds: 0.3) {
                UserDefaults.standard.set(true, forKey: ASCConstants.SettingsKeys.forceCreateNewDocument)
                NotificationCenter.default.post(name: ASCConstants.Notifications.shortcutLaunch, object: nil)
            }
            return true
        case ASCConstants.Shortcuts.newSpreadsheet:
            delay(seconds: 0.3) {
                UserDefaults.standard.set(true, forKey: ASCConstants.SettingsKeys.forceCreateNewSpreadsheet)
                NotificationCenter.default.post(name: ASCConstants.Notifications.shortcutLaunch, object: nil)
            }
            return true
        case ASCConstants.Shortcuts.newPresentation:
            delay(seconds: 0.3) {
                UserDefaults.standard.set(true, forKey: ASCConstants.SettingsKeys.forceCreateNewPresentation)
                NotificationCenter.default.post(name: ASCConstants.Notifications.shortcutLaunch, object: nil)
            }
            return true
        default:
            return false
        }
    }
}

extension ASCSceneDelegate {
    private enum Holder {
        static var passcodeLockPresenter: PasscodeLockPresenter!
    }

    var passcodeLockPresenter: PasscodeLockPresenter { return Holder.passcodeLockPresenter }

    private func initPasscodeLock(for window: UIWindow?) {
        let configuration = ASCPasscodeLockConfiguration()
        Holder.passcodeLockPresenter = ASCPasscodeLockPresenter(mainWindow: window, configuration: configuration)
    }
}
