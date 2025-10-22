//
//  NextcloudOCSResponse.swift
//  Documents
//
//  Created by Victor Tihovodov on 16/10/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

final class NextcloudOCSResponse<T: Mappable>: Mappable {
    var ocs: NextcloudOCS<T>?

    required init?(map: Map) {}
    func mapping(map: Map) {
        ocs <- map["ocs"]
    }
}

final class NextcloudOCS<T: Mappable>: Mappable {
    var meta: NextcloudMeta?
    var data: T?

    required init?(map: Map) {}
    func mapping(map: Map) {
        meta <- map["meta"]
        data <- map["data"]
    }
}
