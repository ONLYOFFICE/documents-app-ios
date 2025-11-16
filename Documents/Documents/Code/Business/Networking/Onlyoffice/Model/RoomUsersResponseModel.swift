//
//  RoomUsersResponseModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 26.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

// MARK: - RoomUsersResponceModel

struct RoomUsersResponseModel: Codable {
    let access: ASCShareAccess
    let user: ASCUser
    let sharedToGroup: SharedToGroup?
    let isLocked: Bool
    let isOwner: Bool
    let canEditAccess: Bool

    enum CodingKeys: String, CodingKey {
        case access
        case user = "sharedTo"
        case sharedToGroup = "sharedToGroup"
        case isLocked
        case isOwner
        case canEditAccess
    }
    
    struct SharedToGroup: Codable {
        let id: String
        let name: String
    }
}
