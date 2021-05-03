//
//  NextcloudStorageStats.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 30.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class NextcloudStorageStats: Mappable {
    var owner: String = ""
    var ownerDisplayName: String = ""

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        owner <- map["owner"]
        ownerDisplayName <- map["ownerDisplayName"]
    }
}
