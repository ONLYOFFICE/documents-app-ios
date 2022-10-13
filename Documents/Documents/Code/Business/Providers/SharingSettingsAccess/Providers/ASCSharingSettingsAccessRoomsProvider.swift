//
//  ASCSharingSettingsAccessRoomsProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 13.10.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessRoomsProvider: ASCSharingSettingsAccessProvider {
    func get() -> [ASCShareAccess] {
        [.fillForms, .review, .comment, .read, .deny]
    }
}
