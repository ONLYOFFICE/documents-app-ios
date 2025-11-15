//
//  SharingInfoViewModelService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 11.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol SharingInfoViewModelService {
    var title: String { get }
    var navbarSubtitle: String { get }
    var isPossibleCreateNewLink: Bool { get }
    var isSharingPossible: Bool { get }
    var isAddingLinksAvailable: Bool { get }
    var isUserSelectionAllow: Bool { get }
    var canRemoveGeneralLink: Bool { get }
    var entityDescription: String? { get }
}

final class SharingInfoViewModelServiceImp {
    private let entityType: SharingInfoEntityType

    init(entityType: SharingInfoEntityType) {
        self.entityType = entityType
    }
}

// MARK: - SharingInfoViewModelService

extension SharingInfoViewModelServiceImp: SharingInfoViewModelService {
    var title: String {
        switch entityType {
        case let .room(room):
            return room.title
        case .file, .folder:
            return NSLocalizedString("Sharing settings", comment: "")
        }
    }
    
    var navbarSubtitle: String {
        switch entityType {
        case let .room(room):
            switch room.roomType {
            case .public:
                return NSLocalizedString("Public room", comment: "")
            case .custom:
                return NSLocalizedString("Custom Room", comment: "")
            case .colobaration:
                return NSLocalizedString("Collaboration Room", comment: "")
            case .fillingForm:
                return NSLocalizedString("Form Filling Room", comment: "")
            case .virtualData:
                return NSLocalizedString("Virtual Data Room", comment: "")
            default:
                return ""
            }
        case .file:
            return ""
        case .folder:
            return ""
        }
    }

    var isPossibleCreateNewLink: Bool {
        switch entityType {
        case let .room(room):
            switch room.roomType {
            case .colobaration, .virtualData:
                return false
            default:
                return true
            }
        case .file:
            return true
        case .folder:
            return true
        }
    }

    var isSharingPossible: Bool {
        return switch entityType {
        case let .room(room):
            room.rootFolderType != .archive && room.security.editAccess
        case .file:
            true
        case .folder:
            true
        }
    }

    var isAddingLinksAvailable: Bool {
        switch entityType {
        case let .room(room):
            !room.isFillingFormRoom
        case .file:
            true
        case .folder:
            true
        }
    }

    var isUserSelectionAllow: Bool {
        switch entityType {
        case let .room(room):
            room.rootFolderType != .archive && room.security.editAccess
        case .file:
            true
        case .folder:
            true
        }
    }

    var canRemoveGeneralLink: Bool {
        switch entityType {
        case let .room(room):
            room.isPublicRoom == false
        case .file:
            true
        case .folder:
            true
        }
    }

    var entityDescription: String? {
        switch entityType {
        case let .room(room):
            switch room.roomType {
            case .fillingForm:
                return .fillingFormRoomDescription
            case .public:
                return .publicRoomDescription
            case .custom:
                return .customRoomDescription
            default:
                return nil
            }
        case .file:
            return NSLocalizedString("Provide access to the document and set the permission levels.", comment: "")
        case .folder:
            return NSLocalizedString("Provide access to the folder and set the permission levels.", comment: "")
        }
    }
}

private extension String {
    static let fillingFormRoomDescription = NSLocalizedString("This room is available to anyone with the link.\n External users will have Form Filler permission\n for all the files.", comment: "")
    static let publicRoomDescription = NSLocalizedString("This room is available to anyone with the link.\n External users will have View Only permission\n for all the files.", comment: "")
    static let customRoomDescription = NSLocalizedString("This room is available to anyone with the link.\n External users will have View Only permission\n for all the files.", comment: "")
}
