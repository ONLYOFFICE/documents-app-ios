//
//  ASCConnectStorageYandexController.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 30.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation
import UIKit
import YandexLoginSDK

class ASCConnectStorageYandexController: YandexLoginSDKObserver {
    var complation: (([String: Any]) -> Void)?

    init() {
        YandexLoginSDK.shared.add(observer: self)
    }

    func didFinishLogin(with result: Result<LoginResult, Error>) {
        var info: [String: Any] = [
            "providerKey": ASCFolderProviderType.yandex.rawValue,
        ]
        do {
            let loginResult = try result.get()
            let token = loginResult.token

            info["token"] = token
            complation?(info)
        } catch {
            print("loginResult error: \(error.localizedDescription)")
        }
    }

    func signIn(parentVC: UIViewController) {
        do {
            try YandexLoginSDK.shared.authorize(with: parentVC)
        } catch {
            print("signIn error: \(error.localizedDescription)")
        }
    }
}
