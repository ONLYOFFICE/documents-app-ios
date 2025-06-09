//
//  ASCTemplateAccessModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 06.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import ObjectMapper

class ASCTemplateAccessModel: Mappable {
    
    var access: ASCShareAccess?
    var sharedTo: ASCTemplateAccessSharedToModel?
    var subjectType: SubjectType?
    var isOwner: Bool = false
    
    init(
        access: ASCShareAccess?,
        sharedTo: ASCTemplateAccessSharedToModel?,
        subjectType: SubjectType?
    ) {
        self.access = access
        self.sharedTo = sharedTo
        self.subjectType = subjectType
    }
    
    required init?(map: ObjectMapper.Map) {}
    
    func mapping(map: ObjectMapper.Map) {
        access <- (map["access"], EnumTransform())
        sharedTo <- map["sharedTo"]
        subjectType <-  (map["subjectType"], EnumTransform())
        isOwner <- map["isOwner"]
    }
}

class ASCTemplateAccessSharedToModel: Mappable {
    
    var id: String?
    var name: String?
    var avatar: String?
    
    required init?(map: ObjectMapper.Map) {}
    
    init(
        id: String? = nil,
        name: String? = nil,
        avatar: String? = nil
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
    }
    
    func mapping(map: ObjectMapper.Map) {
        id <- (map["id"], ASCStringTransform())
        name <- (map["name"], ASCStringTransform())
        if name == nil {
            name <- (map["displayName"], ASCStringTransform())
        }
        avatar <- (map["avatar"], ASCStringTransform())
    }
}

enum SubjectType: Int, Codable {
    case user = 0
    case group = 2
}

extension ASCTemplateAccessModel {
    var isUser: Bool {
        subjectType == .user
    }

    var isGroup: Bool {
        subjectType == .group
    }
}
