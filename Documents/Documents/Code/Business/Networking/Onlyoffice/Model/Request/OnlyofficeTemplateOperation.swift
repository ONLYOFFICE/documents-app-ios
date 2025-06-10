//
//  OnlyofficeTemplateOperation.swift
//  Documents
//
//  Created by Lolita Chernysheva on 26.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

final class OnlyofficeTemplateOperation: Mappable {
    var templateId: Int?
    var progress: Int?
    var error: String?
    var isCompleted: Bool = false

    required init?(map: Map) {}

    func mapping(map: Map) {
        templateId <- map["templateId"]
        progress <- map["progress"]
        error <- map["error"]
        isCompleted <- map["isCompleted"]
    }
}
