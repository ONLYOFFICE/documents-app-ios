//
//  NextcloudDataResult.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class NextcloudDataResult<T: Mappable>: Mappable {
    var result: T?

    required convenience init?(map: Map) {
        self.init()
    }

    func mapping(map: Map) {
        result <- map["data"]
    }
}
