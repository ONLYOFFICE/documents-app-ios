//
//  ASCTariff.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 02.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

struct ASCTariff: Mappable {
    var customerId: String?
    var delayDueDate: String?
    var dueDate: String?
    var id: Int?
    var licenseDate: String?
    var quotas: [ASCQuotasTariff]?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        customerId <- map["customerId"]
        delayDueDate <- map["delayDueDate"]
        dueDate <- map["dueDate"]
        id <- map["id"]
        licenseDate <- map["licenseDate"]
        quotas <- map["quotas"]
    }
}

struct ASCQuotasTariff: Mappable {
    var id: String?
    var quantity: String?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        id <- map["id"]
        quantity <- map["quantity"]
    }
}
