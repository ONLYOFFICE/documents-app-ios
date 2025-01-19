//
//  ASCSharingSettingsAccessRoomsProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 13.10.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessRoomsProvider: ASCSharingSettingsAccessProvider {
    let roomType: ASCRoomType
    let rightHoldersTableType: RightHoldersTableType?

    init(roomType: ASCRoomType, rightHoldersTableType: RightHoldersTableType?) {
        self.roomType = roomType
        self.rightHoldersTableType = rightHoldersTableType
    }

    func get() -> [ASCShareAccess] {
        switch roomType {
        case .fillingForm:
            switch rightHoldersTableType {
            case .users, .none:
                return [.contentCreator, .fillForms]
            case .groups:
                return [.fillForms]
            }
        case .colobaration:
            return [.contentCreator, .editing, .read]

        case .review:
            return [.contentCreator, .review, .comment, .read]

        case .viewOnly:
            return [.contentCreator, .read]

        case .custom:
            return [.contentCreator, .editing, .fillForms, .review, .comment, .read]

        case .public:
            return [.contentCreator]
        case .virtualData:
            return [.contentCreator, .editing, .read]
        }
    }
}
