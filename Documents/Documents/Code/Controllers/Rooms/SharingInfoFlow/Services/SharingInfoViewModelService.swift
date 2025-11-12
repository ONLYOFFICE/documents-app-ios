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
        case .file:
            // TODO: Sharing info stub
            return ""
        case .folder:
            // TODO: Sharing info stub
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
            // TODO: Sharing info stub
            return false
        case .folder:
            // TODO: Sharing info stub
            return false
        }
    }

    var isSharingPossible: Bool {
        return switch entityType {
        case let .room(room):
            room.rootFolderType != .archive && room.security.editAccess
        case .file:
            // TODO: Sharing info stub
            false
        case .folder:
            // TODO: Sharing info stub
            false
        }
    }

    var isAddingLinksAvailable: Bool {
        switch entityType {
        case let .room(room):
            !room.isFillingFormRoom
        case .file:
            // TODO: Sharing info stub
            false
        case .folder:
            // TODO: Sharing info stub
            false
        }
    }

    var isUserSelectionAllow: Bool {
        switch entityType {
        case let .room(room):
            room.rootFolderType != .archive && room.security.editAccess
        case .file:
            // TODO: Sharing info stub
            false
        case .folder:
            // TODO: Sharing info stub
            false
        }
    }

    var canRemoveGeneralLink: Bool {
        switch entityType {
        case let .room(room):
            room.isPublicRoom == false
        case .file:
            // TODO: Sharing info stub
            false
        case .folder:
            // TODO: Sharing info stub
            false
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
            // TODO: Sharing info stub
            return nil
        case .folder:
            // TODO: Sharing info stub
            return nil
        }
    }
}

private extension String {
    static let fillingFormRoomDescription = NSLocalizedString("This room is available to anyone with the link.\n External users will have Form Filler permission\n for all the files.", comment: "")
    static let publicRoomDescription = NSLocalizedString("This room is available to anyone with the link.\n External users will have View Only permission\n for all the files.", comment: "")
    static let customRoomDescription = NSLocalizedString("This room is available to anyone with the link.\n External users will have View Only permission\n for all the files.", comment: "")
}
