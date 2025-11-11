//
//  SharingInfoViewModelService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 11.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

protocol SharingInfoViewModelService {
    var isPossibleCreateNewLink: Bool { get } 
    var isSharingPossible: Bool { get }
    var isUserSelectionAllow: Bool { get }
}

final class SharingInfoViewModelServiceImp {
    
    private let entityType: SharingInfoEntityType
    
    init(entityType: SharingInfoEntityType) {
        self.entityType = entityType
    }
    
}

// MARK: - SharingInfoViewModelService

extension SharingInfoViewModelServiceImp: SharingInfoViewModelService {
    
    var isPossibleCreateNewLink: Bool {
        switch entityType {
        case let .room(room):
            switch room.roomType {
            case .colobaration, .virtualData:
                return false
            default:
                return true
            }
        }
    }
    
    var isSharingPossible: Bool {
        switch entityType {
        case let .room(room):
            room.rootFolderType != .archive && room.security.editAccess
        }
    }
    
    var isUserSelectionAllow: Bool {
        switch entityType {
        case let .room(room):
            room.rootFolderType != .archive && room.security.editAccess
        }
    }
}
