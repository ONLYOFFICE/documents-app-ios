//
//  ASCEntitySecurity.swift
//  Documents
//
//  Created by Pavel Chernyshev on 05/02/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCEntittySecurity: Mappable {
    var read: Bool = false
    var create: Bool = false
    var delete: Bool = false
    var editRoom: Bool = false
    var rename: Bool = false
    var copyTo: Bool = false
    var copy: Bool = false
    var moveTo: Bool = false
    var move: Bool = false
    var pin: Bool = false
    var editAccess: Bool = false
    var duplicate: Bool = false

    init() {}

    required init?(map: Map) {}

    func mapping(map: Map) {
        read <- map["Read"]
        create <- map["Create"]
        delete <- map["Delete"]
        editRoom <- map["EditRoom"]
        rename <- map["Rename"]
        copyTo <- map["CopyTo"]
        copy <- map["Copy"]
        moveTo <- map["MoveTo"]
        move <- map["Move"]
        pin <- map["Pin"]
        editAccess <- map["EditAccess"]
        duplicate <- map["Duplicate"]
    }
}
