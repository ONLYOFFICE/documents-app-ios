//
//  RoomLinkResponseModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 21.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

typealias RoomSharingLinkModel = RoomLinkResponseModel

struct RoomLinkResponseModel: Codable {
    var access: ASCShareAccess
    let linkInfo: SharingLinkInfo
    let isLocked: Bool
    let isOwner: Bool
    let canEditAccess: Bool

    enum CodingKeys: String, CodingKey {
        case access
        case linkInfo = "sharedTo"
        case isLocked
        case isOwner
        case canEditAccess
    }
}

extension RoomLinkResponseModel {
    struct SharingLinkInfo: Codable {
        let id: String
        let title: String
        let shareLink: String
        let expirationDate: String?
        let linkType: ASCShareLinkType
        let password: String?
        let denyDownload: Bool
        let isExpired: Bool
        let primary: Bool
        let `internal`: Bool
        let requestToken: String?

        enum CodingKeys: String, CodingKey {
            case id, title, shareLink, expirationDate, linkType, password, denyDownload, isExpired, primary, `internal`, requestToken
        }
    }
}

extension RoomLinkResponseModel {
    var isGeneral: Bool {
        linkInfo.primary
    }
}
