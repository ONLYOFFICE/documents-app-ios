//
//  ASCPaymentQuota.swift
//  Documents
//
//  Created by Pavel Chernyshev on 08/11/22.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

struct ASCPaymentQuota: Mappable {
    var id: Int?
    var title: String?
    var price: ASCPaymentQuotaPrice?
    var nonProfit: Bool?
    var free: Bool?
    var trial: Bool?
    var features: [ASCPaymentQuotaFeatures] = []
    var roomsQuota: ASCPaymentQuotaSettings?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        id <- map["id"]
        title <- map["title"]
        price <- map["price"]
        nonProfit <- map["nonProfit"]
        free <- map["free"]
        trial <- map["trial"]
        features <- map["features"]
        roomsQuota <- map["roomsQuota"]
    }
}

struct ASCPaymentQuotaFeatures: Mappable {
    static let managerId = "manager"
    static let totalSizeId = "total_size"
    static let fileSizeId = "file_size"
    static let usersId = "users"
    static let roomId = "room"
    static let whitelabelId = "whitelabel"
    static let ssoId = "sso"
    static let restoreId = "restore"
    static let auditId = "audit"
    static let usersInRoomId = "usersInRoom"
    static let statistic = "statistic"

    var id: String?
    var value: Int?
    var type: String?
    var used: ASCPaymentQuotaUsed?
    var priceTitle: String?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        id <- map["id"]
        value <- map["value"]
        type <- map["type"]
        used <- map["used"]
        priceTitle <- map["priceTitle"]
    }
}

struct ASCPaymentQuotaUsed: Mappable {
    var value: Int?
    var title: String?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        value <- map["value"]
        title <- map["title"]
    }
}

struct ASCPaymentQuotaPrice: Mappable {
    var value: Double?
    var currencySymbol: String?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        value <- map["value"]
        currencySymbol <- map["currencySymbol"]
    }
}

struct ASCPaymentQuotaSettings: Mappable, Equatable {
    var enableQuota: Bool?
    var defaultQuota: Double?
    var lastRecalculateDate: String?

    init?(map: Map) {}

    init(
        enableQuota: Bool?,
        defaultQuota: Double?,
        lastRecalculateDate: String?
    ) {
        self.enableQuota = enableQuota
        self.defaultQuota = defaultQuota
        self.lastRecalculateDate = lastRecalculateDate
    }

    mutating func mapping(map: Map) {
        enableQuota <- map["enableQuota"]
        defaultQuota <- map["defaultQuota"]
        lastRecalculateDate <- map["lastRecalculateDate"]
    }
}
