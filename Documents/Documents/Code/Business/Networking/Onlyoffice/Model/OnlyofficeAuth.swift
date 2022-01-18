//
//  OnlyofficeAuth.swift
//  Documents
//
//  Created by Alexander Yuzhin on 04.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficeAuth: Mappable {
    var token: String?
    var expires: String?
    var sms: Bool?
    var phoneNoise: String?
    var tfa: Bool?
    var tfaKey: String?
    
    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        token       <- map["token"]
        expires     <- map["expires"]
        sms         <- map["sms"]
        phoneNoise  <- map["phoneNoise"]
        tfa         <- map["tfa"]
        tfaKey      <- map["tfaKey"]
    }
}
