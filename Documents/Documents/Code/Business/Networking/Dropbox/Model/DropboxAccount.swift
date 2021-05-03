//
//  DropboxAccount.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 30.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class DropboxAccount: Mappable {
    var id: String = ""
    var name: [String : Any]?
    var displayName: String? {
        guard let name = name else { return nil }
        return name["display_name"] as? String
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        id <- map["account_id"]
        name <- map["name"]
    }
}
