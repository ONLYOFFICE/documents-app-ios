//
//  ASCPushSubscribed.swift
//  Documents
//
//  Created by Alexander Yuzhin on 24.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCPushSubscribed: Mappable {
    var userId: String?
    var tenantId: Int?
    var firebaseDeviceToken: String?
    var isSubscribed: Bool?

    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        userId <- map["userId"]
        tenantId <- map["tenantId"]
        firebaseDeviceToken <- map["firebaseDeviceToken"]
        isSubscribed <- map["isSubscribed"]
    }
}
