//
//  AppDelegate.swift
//  Documents
//
//  Created by Alexander Yuzhin on 2/6/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import CoreServices
import CoreSpotlight
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn
import Siren
import SwiftyDropbox
import UIKit
import UserNotifications
#if DEBUG
    import Atlantis
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        self.launchOptions = launchOptions

        if ASCCommon.isUnitTesting {
            return true
        }

        #if DEBUG
            Atlantis.start()
        #endif

        ASCStyles.initialize

        ASCLogIntercepter.shared.start()
        ASCAccountsManager.start()

        #if !OPEN_SOURCE
            // Use Firebase library to configure APIs
            FirebaseApp.configure()

            // Reset application badge
            ASCCommon.applicationIconBadgeNumber = 0

            // Register for remote notifications
            Messaging.messaging().delegate = self
            UNUserNotificationCenter.current().delegate = self

            DropboxClientsManager.setupWithAppKey(ASCConstants.Clouds.Dropbox.appId)

            // Initialize searchable promo
            searchablePromoInit()
        #endif

        window = UIWindow()
        window?.overrideUserInterfaceStyle = AppThemeService.theme.overrideUserInterfaceStyle
        window?.rootViewController = ASCRootViewController.instance()
        window?.makeKeyAndVisible()

        // Initialize PasscodeLock presenter
        initPasscodeLock()

        // Check Update
        configureAppUpdater()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: ASCConstants.Notifications.appDidBecomeActive, object: nil)
    }

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void)
    {
        completionHandler(handle(shortcutItem))
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        if userActivity.activityType == CSSearchableItemActionType,
           let info = userActivity.userInfo,
           let selectedIdentifier = info[CSSearchableItemActivityIdentifier] as? String
        {
            log.debug("Selected Identifier: \(selectedIdentifier)")
        }

        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool
    {
        if let bundleTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            for urlType in bundleTypes {
                if let service = urlType["CFBundleURLName"] as? String,
                   let schemes = urlType["CFBundleURLSchemes"] as? [String],
                   let scheme = schemes.last
                {
                    if let _ = url.scheme?.range(of: scheme, options: .caseInsensitive) {
                        if service == "facebook" {
                            return ASCFacebookSignInController.application(app, open: url, options: options)
                        } else if service == "google" {
                            return GIDSignIn.sharedInstance.handle(url)
                        } else if service == "dropbox" {
                            return DropboxClientsManager.handleRedirectURL(url, completion: ASCDropboxSDKWrapper.shared.handleOAuthRedirect)
                        } else if service == "oodocuments" {
                            return ASCViewControllerManager.shared.route(by: url, options: options)
                        }
                    }
                }
            }
        }

        if url.isFileURL {
            return ASCViewControllerManager.shared.route(by: url, options: options)
        }

        return false
    }

    private func handle(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
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

    private func searchablePromoInit() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [ASCConstants.Searchable.domainPromo]) { error in
            var searchableItems = [CSSearchableItem]()

            for (index, keyword) in ASCConstants.Searchable.promoKeywords.enumerated() {
                let searchItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
                searchItemAttributeSet.title = keyword

                let searchableItem = CSSearchableItem(
                    uniqueIdentifier: "\(index)",
                    domainIdentifier: ASCConstants.Searchable.domainPromo,
                    attributeSet: searchItemAttributeSet
                )
                searchableItems.append(searchableItem)
            }

            CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }

    private func configureAppUpdater() {
        let siren = Siren.shared
        let rules = Rules(promptFrequency: .immediately, forAlertType: .option)

        Siren.shared.rulesManager = RulesManager(globalRules: rules,
                                                 showAlertAfterCurrentVersionHasBeenReleasedForDays: 1)

        siren.wail()
    }
}
