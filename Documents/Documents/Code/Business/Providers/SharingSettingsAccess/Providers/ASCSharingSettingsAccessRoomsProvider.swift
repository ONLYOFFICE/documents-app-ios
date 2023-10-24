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

    init(roomType: ASCRoomType) {
        self.roomType = roomType
    }

    func get() -> [ASCShareAccess] {
        switch roomType {
        case .fillingForm:
            return [.roomManager, .powerUser, .fillForms, .read]
        case .colobaration:
            return [.roomManager, .powerUser, .editing, .read]
        case .review:
            return [.roomManager, .powerUser, .review, .comment, .read]
        case .viewOnly:
            return [.roomManager, .powerUser, .read]
        case .custom:
            return [.roomManager, .powerUser, .editing, .fillForms, .review, .comment, .read]
        }
    }
}
