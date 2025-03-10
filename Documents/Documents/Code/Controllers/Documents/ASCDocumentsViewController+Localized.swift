//
//  ASCDocumentsViewController+Localized.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 24.02.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation

extension ASCDocumentsViewController {
    enum AlertMessageType: String {
        case deleteFileFromTrash
        case deleteRoomFromArchive
        case restoreRoomFromArchive

        var message: String {
            switch self {
            case .deleteFileFromTrash:
                return NSLocalizedString("You are about to delete this file. The file will be permanently deleted in 30 days. Are you sure you want to continue?", comment: "")
            case .deleteRoomFromArchive:
                return NSLocalizedString("You are about to delete this room. You won't be able to restore them.", comment: "")
            case .restoreRoomFromArchive:
                return NSLocalizedString("All shared links in this room will become active, and its contents will be available to everyone with the link. Do you want to restore the room?", comment: "")
            }
        }
    }
}
