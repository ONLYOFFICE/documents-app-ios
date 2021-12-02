//
//  ASCSharingSettingsAccessDocumentFormProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 02.12.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessDocumentFormProvider: ASCSharingSettingsAccessProvider {
    func get() -> [ASCShareAccess] {
        [.full, .review, .comment, .read, .deny]
    }
}
