//
//  OnlyofficeRoomOperation.swift
//  Documents
//
//  Created by Lolita Chernysheva on 20.08.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

final class OnlyofficeRoomOperation: Mappable {
    var id: String?
    var operation: Int?
    var progress: Int?
    var error: String?
    var processed: String?
    var finished: Bool = false

    required init?(map: Map) {}

    func mapping(map: Map) {
        id <- map["id"]
        operation <- map["Operation"]
        progress <- map["progress"]
        error <- map["error"]
        processed <- map["processed"]
        finished <- map["finished"]
    }
}
