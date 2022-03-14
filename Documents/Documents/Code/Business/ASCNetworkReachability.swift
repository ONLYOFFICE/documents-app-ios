//
//  ASCNetworkReachability.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import Alamofire
import UIKit

class ASCNetworkReachability {
    public static let shared = ASCNetworkReachability()

    public var isReachable: Bool {
        if let manager = NetworkReachabilityManager() {
            return manager.isReachable
        }
        return false
    }

    private let reachabilityManager = NetworkReachabilityManager()

    required init() {
        if let reachability = reachabilityManager {
            reachability.startListening { status in
                log.info("Network Status Changed: \(status)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: ASCConstants.Notifications.networkStatusChanged,
                        object: nil,
                        userInfo: ["status": status]
                    )
                }
            }
        }
    }
}
