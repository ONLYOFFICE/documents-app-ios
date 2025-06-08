//
//  ASCSetRoomTemplateAvailableForEveryoneRequestModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 08.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import ObjectMapper

class ASCSetRoomTemplateAvailableForEveryoneRequestModel: Mappable {
    
    var id: Int?
    var `public`: Bool = true
    
    init(id: Int, isPublic: Bool = true) {
        self.id = id
        self.public = isPublic
    }
    
    func mapping(map: Map) {
        id      <- map["id"]
        `public` <- map["public"]
    }
    
    required init?(map: Map) {}
}

