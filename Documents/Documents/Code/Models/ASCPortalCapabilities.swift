//
//  ASCPortalCapabilities.swift
//  Documents
//
//  Created by Alexander Yuzhin on 18/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit
import ObjectMapper

class ASCPortalCapabilities: Mappable {
    var ldapEnabled: Bool = false
    var ssoLabel: String = ""
    var ssoUrl: String = ""
    var providers: [ASCLoginType] = []

    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        ldapEnabled     <- map["ldapEnabled"]
        ssoLabel        <- map["ssoLabel"]
        ssoUrl          <- map["ssoUrl"]
        providers       <- map["providers"]
    }
}
