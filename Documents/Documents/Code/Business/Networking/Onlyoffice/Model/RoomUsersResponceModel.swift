//
//  RoomUsersResponceModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 26.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

// MARK: - RoomUsersResponceModel

struct RoomUsersResponceModel: Codable {
    let access: ASCShareAccess
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

// MARK: - SharedTo

struct SharedTo: Codable {
    let firstName, lastName, userName, email: String
    let status, activationStatus: Int
    let department, workFrom, avatarMax, avatarMedium: String
    let avatar: String
    let isAdmin, isRoomAdmin, isLDAP: Bool
    let listAdminModules: [String]?
    let isOwner, isVisitor, isCollaborator: Bool
    let mobilePhone: String?
    let mobilePhoneActivationStatus: Int
    let isSSO: Bool
    let quotaLimit, usedSpace: Int
    let id, displayName, avatarSmall: String
    let profileURL: String
    let hasAvatar: Bool

    enum CodingKeys: String, CodingKey {
        case firstName, lastName, userName, email, status, activationStatus, department, workFrom, avatarMax, avatarMedium, avatar, isAdmin, isRoomAdmin, isLDAP, listAdminModules, isOwner, isVisitor, isCollaborator, mobilePhone, mobilePhoneActivationStatus, isSSO, quotaLimit, usedSpace, id, displayName, avatarSmall
        case profileURL = "profileUrl"
        case hasAvatar
    }
}
