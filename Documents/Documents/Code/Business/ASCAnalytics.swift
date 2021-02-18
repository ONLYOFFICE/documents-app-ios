//
//  ASCAnalytics.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 20.11.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAnalytics

final class ASCAnalytics {
    class func logEvent(_ event: String, parameters: [String : Any]? = nil) {
        if ASCConstants.Analytics.allow {
            Analytics.logEvent(event, parameters: parameters)
        }
    }
}
