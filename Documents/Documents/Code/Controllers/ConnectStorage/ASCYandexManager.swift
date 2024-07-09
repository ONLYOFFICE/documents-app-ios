//
//  ASCYandexManager.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 09.07.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import YandexLoginSDK

public class ASCYandexManager {
    static func activateYandexLoginSDK() {
        do {
            let clientID = ASCConstants.Clouds.Yandex.appId
            try YandexLoginSDK.shared.activate(with: clientID)
        } catch {
            print("YandexLoginSDK activation error")
        }
    }

    static func handleUserActivity(userActivity: NSUserActivity) {
        do {
            try YandexLoginSDK.shared.handleUserActivity(userActivity)
        } catch {
            print("YandexLoginSDK handleActivityError")
        }
    }

    static func handleURL(url: URL) {
        do {
            try YandexLoginSDK.shared.handleOpenURL(url)
        } catch {
            print("YandexLoginSDK openUrl error")
        }
    }

    static func logout() {
        do {
            try YandexLoginSDK.shared.logout()
        } catch {
            print("failed to logout")
        }
    }
}
