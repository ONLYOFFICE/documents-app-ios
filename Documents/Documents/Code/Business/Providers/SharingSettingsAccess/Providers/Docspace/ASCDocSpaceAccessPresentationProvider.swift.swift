//
//  ASCDocSpaceAccessPresentationProvider.swift.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 24.02.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCDocSpaceAccessPresentationProvider: ASCSharingSettingsAccessProvider {
    func get() -> [ASCShareAccess] {
        [.editing, .comment, .read, .deny]
    }
}
