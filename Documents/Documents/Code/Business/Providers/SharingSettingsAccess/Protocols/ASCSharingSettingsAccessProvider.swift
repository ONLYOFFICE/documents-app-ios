//
//  ASCSharingSettingsAccessProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 07.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCSharingSettingsAccessProvider {
    func get() -> [ASCShareAccess]
}

extension ASCSharingSettingsAccessProvider {
    func get() -> [ASCShareAccess] {
        [.full, .read, .deny]
    }
}
