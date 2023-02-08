//
//  ASCAccessToAddRightHoldersRoomChecker.swift
//  Documents
//
//  Created by Pavel Chernyshev on 08/02/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCAccessToAddRightHoldersRoomChecker: ASCAccessToAddRightHoldersCheckerProtocol {
    let room: ASCFolder

    init(room: ASCFolder) {
        self.room = room
    }

    func checkAccessToAddRightHolders() -> Bool {
        room.security.editAccess
    }
}
