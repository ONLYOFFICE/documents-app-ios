//
//  ASCAccount.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10/23/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import ObjectMapper
import UIKit

enum UserType: String {
    case docspaseAdmin
    case user
    case powerUser
    case roomAdmin

    var description: String {
        switch self {
        case .docspaseAdmin:
            return NSLocalizedString("DocSpace admin", comment: "")
        case .user:
            return NSLocalizedString("User", comment: "")
        case .powerUser:
            return NSLocalizedString("Power user", comment: "")
        case .roomAdmin:
            return NSLocalizedString("Room admin", comment: "")
        }
    }
}

class ASCAccount: NSObject, NSCoding, Mappable {
    var email: String?
    var displayName: String?
    var avatar: String?
    var portal: String?
    var token: String?
    var expires: Date?

    var userType: UserType?
    var avatarAbsoluteUrl: URL? {
        guard let avatarUrlString = self.avatar,
              let portal = portal,
              let portalUrl = URL(string: portal),
              !avatarUrlString.contains("/skins/default/images/default_user_photo_size_"),
              let avatarUrl = URL(string: avatarUrlString)
        else {
            return nil
        }
        return URL(string: (portalUrl.absoluteString) + avatarUrl.absoluteString)
    }

    required init?(map: Map) {
        //
    }

    required init?(coder aDecoder: NSCoder) {
        email = aDecoder.decodeObject(forKey: "email") as? String
        displayName = aDecoder.decodeObject(forKey: "displayName") as? String
        avatar = aDecoder.decodeObject(forKey: "avatar") as? String
        portal = aDecoder.decodeObject(forKey: "portal") as? String
        token = aDecoder.decodeObject(forKey: "token") as? String
        expires = aDecoder.decodeObject(forKey: "expires") as? Date
        userType = UserType(rawValue: (aDecoder.decodeObject(forKey: "userType") as? String) ?? "-")
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(email, forKey: "email")
        aCoder.encode(displayName, forKey: "displayName")
        aCoder.encode(avatar, forKey: "avatar")
        aCoder.encode(portal, forKey: "portal")
        aCoder.encode(token, forKey: "token")
        aCoder.encode(expires, forKey: "expires")
        aCoder.encode(userType?.rawValue ?? "", forKey: "userType")
    }

    func mapping(map: Map) {
        email <- map["email"]
        displayName <- (map["displayName"], ASCStringTransform())
        avatar <- map["avatar"]
        portal <- map["portal"]
        token <- map["token"]
        expires <- (map["expires"], ASCDateTransform())
        userType <- (map["userType"], EnumTransform())
    }
}
