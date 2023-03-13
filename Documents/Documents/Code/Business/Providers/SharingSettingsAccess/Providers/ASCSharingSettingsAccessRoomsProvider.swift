//
//  ASCSharingSettingsAccessRoomsProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 13.10.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessRoomsProvider: ASCSharingSettingsAccessProvider {
    let roomType: ASCRoomType

    init(roomType: ASCRoomType) {
        self.roomType = roomType
    }

    func get() -> [ASCShareAccess] {
        switch roomType {
        case .fillingForm:
            return [.roomManager, .collaborator, .fillForms, .read]
        case .colobaration:
            return [.roomManager, .collaborator, .editing, .read]
        case .review:
            return [.roomManager, .collaborator, .review, .comment, .read]
        case .viewOnly:
            return [.roomManager, .collaborator, .read]
        case .custom:
            return [.roomManager, .collaborator, .editing, .fillForms, .review, .comment, .read, .deny]
        }
    }
}
