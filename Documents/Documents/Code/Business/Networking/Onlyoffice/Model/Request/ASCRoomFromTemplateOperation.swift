//
//  ASCRoomFromTemplateOperation.swift
//  Documents
//
//  Created by Lolita Chernysheva on 29.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

final class ASCRoomFromTemplateOperation: Mappable {
    var roomId: Int?
    var progress: Int?
    var error: String?
    var isCompleted: Bool = false
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        roomId <- map["roomId"]
        progress <- map["progress"]
        error <- map["error"]
        isCompleted <- map["isCompleted"]
    }
}
