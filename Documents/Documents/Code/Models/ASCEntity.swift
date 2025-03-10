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
    var id: String = ""

    var uid: String {
        String(describing: type(of: self)) + "-" + id
    }

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

    var orderIndex: String? {
        get {
            (self as? ASCFile)?.order ?? (self as? ASCFolder)?.order
        }
        set {
            (self as? ASCFile)?.order = newValue
            (self as? ASCFolder)?.order = newValue
        }
    }
}
