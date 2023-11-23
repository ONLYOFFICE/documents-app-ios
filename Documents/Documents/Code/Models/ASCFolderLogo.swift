//
//  ASCFolderLogo.swift
//  Documents
//
//  Created by Victor Tihovodov on 14.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCFolderLogo: Mappable {
    var original: String?
    var large: String?
    var medium: String?
    var small: String?
    var color: String?

    init() {}

    required init?(map: Map) {}

    func mapping(map: Map) {
        original <- map["original"]
        large <- map["large"]
        medium <- map["medium"]
        small <- map["small"]
        color <- map["color"]
    }
}
