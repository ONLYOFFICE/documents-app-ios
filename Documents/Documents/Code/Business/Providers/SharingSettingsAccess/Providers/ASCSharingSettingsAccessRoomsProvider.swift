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
            return [.roomManager, .fillForms, .read]
        case .colobaration:
            return [.roomManager, .editing, .read]
        case .review:
            return [.roomManager, .review, .comment, .read]
        case .viewOnly:
            return [.roomManager, .read]
        case .custom:
            return [.roomManager, .editing, .fillForms, .review, .comment, .read, .deny]
        }
    }
}
