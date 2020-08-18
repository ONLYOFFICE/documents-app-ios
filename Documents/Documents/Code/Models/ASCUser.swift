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
    var userId: String? = nil
    var displayName: String? = nil
    var userName: String? = nil
    var firstName: String? = nil
    var lastName: String? = nil
    var title: String? = nil
    var avatarSmall: String? = nil
    var department: String? = nil
    var email: String? = nil
    var avatar: String? = nil
    var isAdmin: Bool = false
    var isVisitor: Bool = false
    var isShareOwner: Bool = false
    var accessValue: ASCShareAccess = .none

    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        userId          <- (map["id"], ASCIndexTransform())
        displayName     <- (map["displayName"], ASCStringTransform())
        userName        <- (map["userName"], ASCStringTransform())
        firstName       <- (map["firstName"], ASCStringTransform())
        lastName        <- (map["lastName"], ASCStringTransform())
        title           <- (map["title"], ASCStringTransform())
        avatarSmall     <- map["avatarSmall"]
        department      <- (map["department"], ASCStringTransform())
        email           <- map["email"]
        avatar          <- map["avatar"]
        isAdmin         <- map["isAdmin"]
        isVisitor       <- map["isVisitor"]
        isShareOwner    <- map["isOwner"]
        accessValue     <- (map["access"], EnumTransform())
        
        if let _ = map.JSON["sharedTo"] {
            displayName <- (map["sharedTo.displayName"], ASCStringTransform())
            userId      <- map["sharedTo.id"]
        }
    }
}
