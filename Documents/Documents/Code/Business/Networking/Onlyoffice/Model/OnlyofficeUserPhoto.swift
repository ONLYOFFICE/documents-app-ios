//
//  OnlyofficeUserPhoto.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficeUserPhoto: Mappable {
    var big: String?
    var max: String?
    var medium: String?
    var original: String?
    var retina: String?
    var small: String?

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        big <- map["big"]
        max <- map["max"]
        medium <- map["medium"]
        original <- map["original"]
        retina <- map["retina"]
        small <- map["small"]
    }
}
