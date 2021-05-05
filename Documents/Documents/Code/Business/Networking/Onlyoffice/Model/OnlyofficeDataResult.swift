//
//  OnlyofficeDataResult.swift
//  Documents
//
//  Created by Alexander Yuzhin on 04.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficeDataResult<T: Mappable>: Mappable {

    var result: T? = nil
    var count: Int?
    var status: Int?
    var statusCode: Int?

    required convenience init?(map: Map) {
        self.init()
    }

    func mapping(map: Map) {
        count       <- map["count"]
        status      <- map["status"]
        statusCode  <- map["statusCode"]
        result      <- map["response"]
    }
}
