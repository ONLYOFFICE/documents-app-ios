//
//  RoomLinkResponceModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 21.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

struct RoomLinkResponceModel: Codable {
    let access: Int
    let sharedTo: SharedTo
    let isLocked: Bool
    let isOwner: Bool
    let canEditAccess: Bool

    enum CodingKeys: String, CodingKey {
        case access
        case sharedTo
        case isLocked
        case isOwner
        case canEditAccess
    }
}

extension RoomLinkResponceModel {
    struct SharedTo: Codable {
        let id: String
        let title: String
        let shareLink: String
        let expirationDate: String?
        let linkType: Int
        let password: String?
        let denyDownload: Bool
        let isExpired: Bool
        let primary: Bool
        let requestToken: String

        enum CodingKeys: String, CodingKey {
            case id, title, shareLink, expirationDate, linkType, password, denyDownload, isExpired, primary, requestToken
        }
    }
}
