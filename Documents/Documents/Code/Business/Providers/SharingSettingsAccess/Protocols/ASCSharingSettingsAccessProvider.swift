//
//  ASCSharingSettingsAccessProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 07.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCSharingSettingsAccessProvider {
    func get(rightHoldersTableType: RightHoldersTableType?) -> [ASCShareAccess]
}

extension ASCSharingSettingsAccessProvider {
    func get(rightHoldersTableType: RightHoldersTableType? = nil) -> [ASCShareAccess] {
        [.full, .read, .deny]
    }
}
