//
//  ASCRoomTemplateInviteRequestModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 07.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCRoomTemplateInviteRequestModel: Mappable {
    var invitations: [ASCRoomTemplateInviteItemRequestModel]?
    var notify: Bool = false
    var sharingMessage: String?

    init(invitations: [ASCRoomTemplateInviteItemRequestModel]? = nil, notify: Bool, sharingMessage: String? = nil) {
        self.invitations = invitations
        self.notify = notify
        self.sharingMessage = sharingMessage
    }

    required init?(map: Map) {}

    func mapping(map: Map) {
        invitations <- map["invitations"]
        notify <- map["notify"]
        sharingMessage <- map["sharingMessage"]
    }
}

class ASCRoomTemplateInviteItemRequestModel: Mappable {
    var id: String?
    var access: ASCShareAccess = .none

    init(id: String? = nil, access: ASCShareAccess) {
        self.id = id
        self.access = access
    }

    required init?(map: Map) {}

    func mapping(map: Map) {
        id <- map["id"]
        access <- map["access"]
    }
}
