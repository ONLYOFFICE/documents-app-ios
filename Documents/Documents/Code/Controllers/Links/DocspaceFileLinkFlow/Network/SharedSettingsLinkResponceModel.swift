//
//  SharedSettingsLinkResponceModel.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 03.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct SharedSettingsLinkResponceModel: Codable {
    var access: Int
    var sharedTo: LinkInfo
}

struct LinkInfo: Codable {
    let id: String
    let title: String
    let shareLink: String
    let expirationDate: String?
    let linkType: Int
    let denyDownload: Bool
    let isExpired: Bool
    let primary: Bool
    let isInternal: Bool
    let requestToken: String?

    enum CodingKeys: String, CodingKey {
        case isInternal = "internal"
        case id, title, shareLink, expirationDate, linkType, denyDownload, isExpired, primary, requestToken
    }
}

extension LinkInfo {
    
    var linkAccess: LinkAccess {
        isInternal ? .docspaceUserOnly : .anyoneWithLink
    }
}
