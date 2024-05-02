//
//  ASCTenantExtra.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 02.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

struct ASCTenantExtra: Mappable {
    var customMode: Bool?
    var enableTariffPage: Bool?
    var enterprise: Bool?
    var licenseAccept: String?
    var notPaid: Bool?
    var opensource: Bool?
    var quota: ASCPaymentQuota?
    var tariff: ASCTariff?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        customMode <- map["customMode"]
        enableTariffPage <- map["enableTariffPage"]
        enterprise <- map["enterprise"]
        licenseAccept <- map["licenseAccept"]
        notPaid <- map["notPaid"]
        opensource <- map["opensource"]
        quota <- map["quota"]
        tariff <- map["tariff"]
    }
}
