//
//  ASCAccount.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10/23/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import ObjectMapper
import UIKit

class ASCAccount: NSObject, NSCoding, Mappable {
    var email: String?
    var displayName: String?
    var avatar: String?
    var portal: String?
    var token: String?
    var expires: Date?

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
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(email, forKey: "email")
        aCoder.encode(displayName, forKey: "displayName")
        aCoder.encode(avatar, forKey: "avatar")
        aCoder.encode(portal, forKey: "portal")
        aCoder.encode(token, forKey: "token")
        aCoder.encode(expires, forKey: "expires")
    }

    func mapping(map: Map) {
        email <- map["email"]
        displayName <- (map["displayName"], ASCStringTransform())
        avatar <- map["avatar"]
        portal <- map["portal"]
        token <- map["token"]
        expires <- (map["expires"], ASCDateTransform())
    }
}
