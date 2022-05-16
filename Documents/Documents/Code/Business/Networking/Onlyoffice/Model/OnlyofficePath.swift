//
//  OnlyofficePath.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficePath: Mappable {
    var count: Int = 0
    var current: ASCFolder?
    var files: [ASCFile] = []
    var folders: [ASCFolder] = []
    var pathParts: [Int] = []
    var startIndex: Int = 0
    var total: Int = 0

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        count <- map["count"]
        current <- map["current"]
        files <- map["files"]
        folders <- map["folders"]
        pathParts <- map["pathParts"]
        startIndex <- map["startIndex"]
        total <- map["total"]
    }
}
