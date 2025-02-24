//
//  ASCSharingSettingsAccessDocumentProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 07.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessDocumentProvider: ASCSharingSettingsAccessProvider {
    func get() -> [ASCShareAccess] {
        [.editing, .review, .comment, .read, .deny]
    }
}
