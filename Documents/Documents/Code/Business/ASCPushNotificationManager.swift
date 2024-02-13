//
//  ASCPushNotificationManager.swift
//  Documents
//
//  Created by Alexander Yuzhin on 26.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCPushNotificationManager {
    static func requestRegister(fcmToken: String? = nil) {
        if let fcmToken = fcmToken {
            UserDefaults.standard.set(fcmToken, forKey: ASCConstants.SettingsKeys.pushFCMToken)
        }

        guard
            let fcmToken = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.pushFCMToken)
        else { return }

        if OnlyofficeApiClient.shared.active {
            let params = ASCPushSubscribed()
            params.firebaseDeviceToken = fcmToken

            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Push.pushRegisterDevice, params.toJSON()) { response, error in
                if let error = error {
                    log.error(error)
                    return
                }

                let params = ASCPushSubscribed()
                params.firebaseDeviceToken = fcmToken
                params.isSubscribed = UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.pushAllNotification)

                OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Push.pushSubscribe, params.toJSON()) { response, error in
                    if let error = error {
                        log.error(error)
                    }
                }
            }
        }
    }

    static func requestClearRegister(fcmToken: String? = nil) {
        if let fcmToken = fcmToken {
            UserDefaults.standard.set(fcmToken, forKey: ASCConstants.SettingsKeys.pushFCMToken)
        }

        guard
            let fcmToken = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.pushFCMToken)
        else { return }

        if OnlyofficeApiClient.shared.active {
            let params = ASCPushSubscribed()
            params.firebaseDeviceToken = fcmToken
            params.isSubscribed = false

            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Push.pushSubscribe, params.toJSON()) { response, error in
                if let error = error {
                    log.error(error)
                }
            }
        }
    }
}
