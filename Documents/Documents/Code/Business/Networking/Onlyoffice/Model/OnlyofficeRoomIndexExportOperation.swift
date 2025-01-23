//
//  OnlyofficeRoomIndexExportOperation.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 22.01.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

final class OnlyofficeRoomIndexExportOperation: Mappable {
    var id: String?
    var error: String?
    var percentage: Int?
    var isCompleted: Bool = false
    var status: Int?
    var resultFileId: Int?
    var resultFileName: String?
    var resultFileUrl: String?

    required init?(map: Map) {}

    func mapping(map: Map) {
        id <- map["id"]
        error <- map["error"]
        percentage <- map["percentage"]
        isCompleted <- map["isCompleted"]
        status <- map["status"]
        resultFileId <- map["resultFileId"]
        resultFileName <- map["resultFileName"]
        resultFileUrl <- map["resultFileUrl"]
    }
}
