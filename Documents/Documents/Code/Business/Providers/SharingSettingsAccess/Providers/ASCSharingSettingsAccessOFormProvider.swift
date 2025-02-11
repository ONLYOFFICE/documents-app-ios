//
//  ASCSharingSettingsAccessOFormProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 03.12.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessOFormProvider: ASCSharingSettingsAccessProvider {
    func get() -> [ASCShareAccess] {
        [.editing, .fillForms, .read, .deny]
    }
}
