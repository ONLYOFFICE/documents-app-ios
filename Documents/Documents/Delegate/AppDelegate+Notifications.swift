//
//  AppDelegate+Notifications.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Firebase
import FirebaseMessaging
import UIKit

extension AppDelegate {

    func checkNotifications() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { [weak self] settings in
            let status = settings.authorizationStatus

            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    ASCPushNotificationManager.requestRegister()
                }
            case .denied:
                log.warning("Push not authorized")
                ASCPushNotificationManager.requestClearRegister()
            case .notDetermined:
                center.requestAuthorization(options: [.badge, .alert, .sound]) { [weak self] granted, error in
                    guard let strongSelf = self else { return }
                    strongSelf.checkNotifications()
                }

                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            default:
                break
            }
        }
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any])
    {
        log.debug(userInfo)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        UserDefaults.standard.set(userInfo, forKey: ASCConstants.SettingsKeys.pushUserInfo)
        NotificationCenter.default.post(name: ASCConstants.Notifications.pushInfo, object: nil)

        log.debug(userInfo)

        completionHandler(UIBackgroundFetchResult.newData)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error)
    {
        log.debug("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        Messaging.messaging().apnsToken = deviceToken

        log.debug("APNs token retrieved: \(deviceTokenString)")
        UserDefaults.standard.set(deviceTokenString, forKey: ASCConstants.SettingsKeys.pushDeviceToken)

        subscribePromoTopic()
    }

    private func subscribePromoTopic() {
        let prefix = "ios-documents-promo-"
        let avalibleLang = ASCConstants.Locale.avalibleLangCodes
        var regionCode = (Locale.preferredLanguages.first ?? ASCConstants.Locale.defaultLangCode)[0 ..< 2].uppercased()

        if !avalibleLang.contains(regionCode) {
            regionCode = ASCConstants.Locale.defaultLangCode
        }

        for code in avalibleLang {
            Messaging.messaging().unsubscribe(fromTopic: prefix + code)
        }

        Messaging.messaging().subscribe(toTopic: prefix + regionCode)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        let userInfo = notification.request.content.userInfo

        // Print full message.
        log.debug(userInfo)

        // Change this to your preferred presentation option
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
        let userInfo = response.notification.request.content.userInfo

        UserDefaults.standard.set(userInfo, forKey: ASCConstants.SettingsKeys.pushUserInfo)
        NotificationCenter.default.post(name: ASCConstants.Notifications.pushInfo, object: nil)

        // Print full message.
        log.debug(userInfo)

        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging,
                   didReceiveRegistrationToken fcmToken: String?)
    {
        guard let fcmToken = fcmToken else {
            log.error("FirebaseMessaging Framework Reference token is not exist")
            return
        }

        log.info("Firebase registration token: \(fcmToken)")
        UserDefaults.standard.set(fcmToken, forKey: ASCConstants.SettingsKeys.pushFCMToken)

        let dataDict: [String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)

        ASCPushNotificationManager.requestRegister(fcmToken: fcmToken)
    }
}
