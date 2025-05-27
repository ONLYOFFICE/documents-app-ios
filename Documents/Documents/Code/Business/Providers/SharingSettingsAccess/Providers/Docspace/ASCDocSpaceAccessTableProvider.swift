//
//  ASCDocSpaceAccessTableProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 24.02.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCDocSpaceAccessTableProvider: ASCSharingSettingsAccessProvider {
    func get() -> [ASCShareAccess] {
        [.editing, .userFilter, .comment, .read, .deny]
    }
}
