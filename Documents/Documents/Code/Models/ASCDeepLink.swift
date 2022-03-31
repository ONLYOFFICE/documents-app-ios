//
//  ASCDeepLink.swift
//  Documents
//
//  Created by Alexander Yuzhin on 30.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCDeepLink: Mappable {
    var portal: String?
    var email: String?
    var originalUrl: String?
    var file: ASCFile?
    var folder: ASCFolder?

    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        portal <- map["portal"]
        email <- map["email"]
        originalUrl <- map["originalUrl"]
        file <- map["file"]
        folder <- map["folder"]
    }
}
