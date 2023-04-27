//
//  ASCUser.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/9/17.
//  Copyright (c) 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCUser: Mappable {
    var userId: String?
    var displayName: String?
    var userName: String?
    var firstName: String?
    var lastName: String?
    var title: String?
    var avatarSmall: String?
    var department: String?
    var email: String?
    var avatar: String?
    var avatarRetina: String?
    var isAdmin: Bool = false
    var isVisitor: Bool = false
    var isShareOwner: Bool = false
    var accessValue: ASCShareAccess = .none

    var userType: UserType {
        return isAdmin ? .admin : isShareOwner ? .owner : .user
    }

    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        userId <- (map["id"], ASCIndexTransform())
        displayName <- (map["displayName"], ASCStringTransform())
        userName <- (map["userName"], ASCStringTransform())
        firstName <- (map["firstName"], ASCStringTransform())
        lastName <- (map["lastName"], ASCStringTransform())
        title <- (map["title"], ASCStringTransform())
        avatarSmall <- map["avatarSmall"]
        department <- (map["department"], ASCStringTransform())
        email <- map["email"]
        avatar <- map["avatar"]
        avatarRetina <- map["avatarRetina"]
        isAdmin <- map["isAdmin"]
        isVisitor <- map["isVisitor"]
        isShareOwner <- map["isOwner"]
        accessValue <- (map["access"], EnumTransform())

        if let _ = map.JSON["sharedTo"] {
            displayName <- (map["sharedTo.displayName"], ASCStringTransform())
            userId <- map["sharedTo.id"]
        }
    }
}
