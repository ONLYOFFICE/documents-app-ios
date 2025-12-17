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
                return [.contentCreator, .roomManager, .fillForms]
            case .groups:
                return [.roomManager, .fillForms]
            case .guests:
                return [.contentCreator, .fillForms]
            }
        case .colobaration:
            return [.roomManager, .contentCreator, .editing, .read]
        case .review:
            return [.roomManager, .contentCreator, .review, .comment, .read]
        case .viewOnly:
            return [.roomManager, .contentCreator, .read]
        case .custom:
            return [.roomManager, .contentCreator, .editing, .review, .comment, .read]
        case .public:
            return [.contentCreator, .roomManager]
        case .virtualData:
            return [.roomManager, .contentCreator, .editing, .read]
        }
    }
}

class ASCSharingSettingsExternalLinkAccessRoomsProvider: ASCSharingSettingsAccessRoomsProvider {
    override func get() -> [ASCShareAccess] {
        var accessList = super.get()
        return accessList.removeAll(.roomManager)
    }
}
