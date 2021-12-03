//
//  ASCSharingSettingsAccessOFormProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 03.12.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessOFormProvider: ASCSharingSettingsAccessProvider {
    func get() -> [ASCShareAccess] {
        [.full, .fillForms, .read, .deny]
    }
}
