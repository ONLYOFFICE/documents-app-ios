//
//  NextcloudUserData.swift
//  Documents
//
//  Created by Victor Tihovodov on 16/10/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

final class NextcloudUserData: Mappable {
    var enabled: Bool?
    var id: String?
    var avatarScope: String?
    var email: String?
    var displayName: String?
    var displayNameAlt: String?
    var displayNameScope: String?
    var phone: String?
    var phoneScope: String?
    var address: String?
    var addressScope: String?
    var backend: String?

    required init?(map: Map) {}

    func mapping(map: Map) {
        enabled <- map["enabled"]
        id <- map["id"]
        avatarScope <- map["avatarScope"]
        email <- map["email"]
        displayName <- map["displayname"]
        displayNameAlt <- map["display-name"]
        displayNameScope <- map["displaynameScope"]
        phone <- map["phone"]
        phoneScope <- map["phoneScope"]
        address <- map["address"]
        addressScope <- map["addressScope"]
        backend <- map["backend"]
    }
}
