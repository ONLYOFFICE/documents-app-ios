//
//  ASCSharingSettingsAccessExternalDefaultProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 07.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessExternalDefaultProvider: ASCSharingSettingsAccessProvider {
    func get() -> [ASCShareAccess] {
        [.read, .deny]
    }
}
