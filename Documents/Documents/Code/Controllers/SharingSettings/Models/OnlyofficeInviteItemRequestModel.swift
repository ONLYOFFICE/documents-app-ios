//
//  OnlyofficeShareRequest.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//
import Foundation
import ObjectMapper

class OnlyofficeInviteItemRequestModel: Mappable {
    var id: String?
    var email: String?
    var access: ASCShareAccess = .none

    init() {}

    convenience init(id: String, access: ASCShareAccess) {
        self.init()
        self.id = id
        self.access = access
    }

    convenience init(email: String, access: ASCShareAccess) {
        self.init()
        self.email = email
        self.access = access
    }

    required init?(map: Map) {}

    func mapping(map: Map) {
        id <- map["id"]
        email <- map["email"]
        access <- (map["access"], EnumTransform())
    }
}

class OnlyofficeInviteRequestModel: Mappable {
    var notify: Bool = false
    var inviteMessage: String?
    var invitations: [OnlyofficeInviteItemRequestModel]?

    init() {}

    required init?(map: Map) {}

    func mapping(map: Map) {
        notify <- map["notify"]
        inviteMessage <- map["message"]
        invitations <- map["invitations"]
    }
}
