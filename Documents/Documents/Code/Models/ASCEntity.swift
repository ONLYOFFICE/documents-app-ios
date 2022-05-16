//
//  ASCEntity.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11/13/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCEntity: Mappable {
    var id: String = "" {
        didSet {
            uid = String(describing: type(of: self)) + "-" + id
        }
    }

    var uid: String = ""
    var isPlaceholder = false

    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        id <- (map["id"], ASCIndexTransform())
    }
}

extension ASCEntity: Equatable {
    static func == (lhs: ASCEntity, rhs: ASCEntity) -> Bool {
        return lhs.uid == rhs.uid
    }
}
