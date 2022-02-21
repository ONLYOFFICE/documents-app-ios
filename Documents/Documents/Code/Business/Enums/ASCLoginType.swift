//
//  ASCLoginType.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCLoginType: String, CaseIterable {
    case undefined = ""
    case email = "email"
    case facebook = "facebook"
    case google = "google"
    case twitter = "twitter"
    case linkedin = "linkedin"
    case openid = "openid"
    case box = "box"
    case sso = "sso"
    case microsoft = "microsoft"

    init() {
        self = .undefined
    }

    init(_ type: String) {
        switch type {
        case "email": self = .email
        case "facebook": self = .facebook
        case "google": self = .google
        case "twitter": self = .twitter
        case "linkedin": self = .linkedin
        case "openid": self = .openid
        case "box": self = .box
        case "sso": self = .sso
        case "microsoft": self = .microsoft
        default: self = .undefined
        }
    }
}
