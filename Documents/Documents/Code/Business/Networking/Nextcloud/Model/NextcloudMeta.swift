//
//  NextcloudMeta.swift
//  Documents
//
//  Created by Victor Tihovodov on 16/10/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

final class NextcloudMeta: Mappable {
    var status: String?
    var statuscode: Int?
    var message: String?

    required init?(map: Map) {}
    func mapping(map: Map) {
        status <- map["status"]
        statuscode <- map["statuscode"]
        message <- map["message"]
    }
}
