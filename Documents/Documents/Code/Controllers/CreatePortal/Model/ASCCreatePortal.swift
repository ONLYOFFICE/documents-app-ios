//
//  ASCCreatePortal.swift
//  Documents
//
//  Created by Alexander Yuzhin on 19.10.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

enum ASCCreatePortalReCaptchaType: Int {
    case iOSV2 = 2
}

class ASCCreatePortal: Mappable {
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var portalName: String?
    var partnerId: String?
    var industry: Int?
    var timeZoneName: String?
    var language: String?
    var password: String?
    var appKey: String?
    var recaptchaResponse: String?
    var recaptchaType: ASCCreatePortalReCaptchaType = .iOSV2
    
    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        firstName           <- map["firstName"]
        lastName            <- map["lastName"]
        email               <- map["email"]
        phone               <- map["phone"]
        portalName          <- map["portalName"]
        partnerId           <- map["partnerId"]
        industry            <- map["industry"]
        timeZoneName        <- map["timeZoneName"]
        language            <- map["language"]
        password            <- map["password"]
        appKey              <- map["appKey"]
        recaptchaResponse   <- map["recaptchaResponse"]
        recaptchaType       <- (map["recaptchaType"], EnumTransform())
    }
    
}
