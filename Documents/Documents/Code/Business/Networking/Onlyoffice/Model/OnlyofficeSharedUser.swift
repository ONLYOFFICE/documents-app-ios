//
//  OnlyofficeSharedUser.swift
//  Documents
//
//  Created by Pavel Chernyshev on 29.09.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import ObjectMapper

struct OnlyofficeSharedUser: Mappable {
    var name: String?
    var email: String?
    var image: String?

    init() {}

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        name <- map["name"]
        email <- map["email"]
        image <- map["image"]
    }
}
