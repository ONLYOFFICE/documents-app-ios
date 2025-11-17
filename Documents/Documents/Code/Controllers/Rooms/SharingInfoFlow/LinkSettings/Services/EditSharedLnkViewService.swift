//
//  EditSharedLnkViewService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 13.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

final class EditSharedLnkViewService {
    private var entity: EditSharedLinkEntityType
    private var link: SharingInfoLinkModel

    init(
        entity: EditSharedLinkEntityType,
        link: SharingInfoLinkModel
    ) {
        self.entity = entity
        self.link = link
    }

    var isDeletePossible: Bool {
        switch entity {
        case let .room(room):
            if (room.roomType == .public && link.isGeneral == true) || room.roomType == .fillingForm {
                return false
            } else {
                return true
            }
        default:
            return !link.isGeneral
        }
    }

    var showRestrictCopySection: Bool {
        return switch entity {
        case let .room(room):
            room.roomType != .fillingForm
        default:
            true
        }
    }

    var isEditAccessPossible: Bool {
        switch entity {
        case let .room(room):
            room.security.editAccess
        case let .folder(folder):
            folder.security.editAccess
        case let .file(file):
            file.security.edit
        }
    }
    
    var showWhoHasAccessSection: Bool {
        switch entity {
        case let .room(room):
            return room.roomType != .public && room.roomType != .virtualData

        case let .folder(folder):
            if let rootFolder = folder.parent {
                return rootFolder.roomType != .public && rootFolder.roomType != .virtualData
            }
            return true

        case let .file(file):
            if let rootFolder = file.parent {
                return rootFolder.roomType != .public && rootFolder.roomType != .virtualData
            }
            return true
        }
    }
}
