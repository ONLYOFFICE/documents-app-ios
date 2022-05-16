//
//  ASCGroup.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/8/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCGroup: Mappable {
    var id: String?
    var name: String?
    var manager: String?

    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        id <- (map["id"], ASCIndexTransform())
        name <- (map["name"], ASCStringTransform())
        manager <- (map["manager"], ASCStringTransform())
    }
}
