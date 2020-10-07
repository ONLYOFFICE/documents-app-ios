//
//  AppDelegate.swift
//  Documents
//
//  Created by Alexander Yuzhin on 2/6/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import UserNotifications
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import FirebaseCore
import FirebaseMessaging
import CoreSpotlight
import CoreServices
import Siren
#if DEBUG
import Bagel
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var passcodeLockPresenter: PasscodeLockPresenter = {
        let configuration = ASCPasscodeLockConfiguration()
        let presenter = ASCPasscodeLockPresenter(mainWindow: self.window, configuration: configuration)
        
        return presenter
    }()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if ASCCommon.isUnitTesting {
            return true
        }
        
        #if DEBUG
        Bagel.start()
        #endif

        ASCLogIntercepter.shared.start()
        
        ASCStyles.initialize
        _ = passcodeLockPresenter
        _ = ASCAccountsManager.shared
                
        // Facebook login
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()

        // Reset application badge
        ASCCommon.applicationIconBadgeNumber = 0
        
        // Register for remote notifications
        Messaging.messaging().delegate = self

        // Initialize searchable promo
        searchablePromoInit()

        // Check Update
        configureAppUpdater()
        
        application.unregisterForRemoteNotifications()
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { (finished, error) in
                    DispatchQueue.main.async {
                        let allow = error == nil
                        if allow {
                            application.registerForRemoteNotifications()
                        }
                        UserDefaults.standard.set(allow, forKey: ASCConstants.SettingsKeys.pushAllow)
                    }
            })
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        log.info("Firebase registration token: \(Messaging.messaging().fcmToken ?? "")")
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NotificationCenter.default.post(name: ASCConstants.Notifications.appDidBecomeActive, object: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handle(shortcutItem))
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // Print full message.
        log.debug(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Print full message.
        log.debug(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        log.debug("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        Messaging.messaging().apnsToken = deviceToken
        
        log.debug("APNs token retrieved: \(deviceTokenString)")
        UserDefaults.standard.set(deviceTokenString, forKey: ASCConstants.SettingsKeys.pushDeviceToken)
        
        subscribePromoTopic()
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == CSSearchableItemActionType,
            let info = userActivity.userInfo,
            let selectedIdentifier = info[CSSearchableItemActivityIdentifier] as? String {
            log.debug("Selected Identifier: \(selectedIdentifier)")
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let bundleTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            for urlType in bundleTypes {
                if let service = urlType["CFBundleURLName"] as? String,
                   let schemes = urlType["CFBundleURLSchemes"] as? [String],
                   let scheme = schemes.last {
                    if let _ = url.scheme?.range(of: scheme, options: .caseInsensitive) {
                        if service == "facebook" {
                            return ApplicationDelegate.shared.application(app, open: url, options: options)
                        } else if service == "google" {
                            return GIDSignIn.sharedInstance().handle(url)
                        } else if service == "oodocuments" {
                            return ASCViewControllerManager.shared.route(by: url, options: options)
                        }
                    }
                }
            }
        }
        
        if url.isFileURL {
            if let sourceApplication = options[.sourceApplication] as? String, "com.apple.DocumentsApp" == sourceApplication {
                NotificationCenter.default.post(name: ASCConstants.Notifications.openLocalFileByUrl, object: nil, userInfo: ["url": url])
            } else {
                UserDefaults.standard.set(url, forKey: ASCConstants.SettingsKeys.importFile)
                NotificationCenter.default.post(name: ASCConstants.Notifications.importFileLaunch, object: nil)
            }
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
    
    private func subscribePromoTopic() {
        let prefix = "ios-documents-promo-"
        let avalibleLang = ASCConstants.Locale.avalibleLangCodes
        var regionCode = (Locale.preferredLanguages.first ?? ASCConstants.Locale.defaultLangCode)[0..<2].uppercased()
        
        if !avalibleLang.contains(regionCode) {
            regionCode = ASCConstants.Locale.defaultLangCode
        }
        
        for code in avalibleLang {
            Messaging.messaging().unsubscribe(fromTopic: prefix + code)
        }
        
        Messaging.messaging().subscribe(toTopic: prefix + regionCode)
    }

    private func searchablePromoInit() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [ASCConstants.Searchable.domainPromo]) { (error) in
            var searchableItems = [CSSearchableItem]()

            for (index, keyword) in ASCConstants.Searchable.promoKeywords.enumerated() {
                let searchItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
                searchItemAttributeSet.title = keyword

                let searchableItem = CSSearchableItem(
                    uniqueIdentifier: "\(index)",
                    domainIdentifier: ASCConstants.Searchable.domainPromo,
                    attributeSet: searchItemAttributeSet)
                searchableItems.append(searchableItem)
            }

            CSSearchableIndex.default().indexSearchableItems(searchableItems) { (error) -> Void in
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

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Print full message.
        log.debug(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        UserDefaults.standard.set(userInfo, forKey: ASCConstants.SettingsKeys.pushUserInfo)
        NotificationCenter.default.post(name: ASCConstants.Notifications.pushInfo, object: nil)

        // Print full message.
        log.debug(userInfo)
        
        completionHandler()
    }
}

extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        UserDefaults.standard.set(fcmToken, forKey: ASCConstants.SettingsKeys.pushFCMToken)

        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
}

