//
//  OwncloudUserData.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 4/11/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation

struct OwncloudUserData: Decodable {
    var email: String?
    var sub: String?
    var givenName: String?
    var familyName: String?
    var emailVerified: Bool?
    var name: String?
    var preferred_username: String?
}
