//
//  OnlyofficeAuthRequest.swift
//  Documents
//
//  Created by Alexander Yuzhin on 04.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficeAuthRequest: Mappable {
    var provider: ASCLoginType = .undefined
    var portal: String?
    var userName: String?
    var password: String?
    var code: String?
    var phoneNoise: String?
    var mobilePhone: String?
    var tfaKey: String?
    var facebookToken: String?
    var googleToken: String?
    var accessToken: String?
    var codeOauth: String?
    
    init() {
        //
    }
    
    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        provider            <- map["provider"]
        portal              <- map["portal"]
        userName            <- map["userName"]
        password            <- map["password"]
        code                <- map["code"]
        phoneNoise          <- map["phoneNoise"]
        mobilePhone         <- map["mobilePhone"]
        tfaKey              <- map["tfaKey"]
        facebookToken       <- map["facebookToken"]
        googleToken         <- map["googleToken"]
        accessToken         <- map["accessToken"]
        codeOauth           <- map["codeOauth"]
    }
}
