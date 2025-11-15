//
//  ASCFolderType.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCFolderType: Int {
    // Default
    case `default` = 0

    // Common
    case common = 1

    // Bunch
    case bunch = 2

    // Trash
    case trash = 3

    // User
    case user = 5

    // Share
    case share = 6

    // Projects
    case projects = 8

    // Favorites
    case favorites = 10

    // Recent
    case recent = 11

    // Templates
    case templates = 12

    // Privacy
    case privacy = 13

    // Virtual rooms
    case virtualRooms = 14

    // Filling forms room
    case fillingFormsRoom = 15

    // Editing room
    case editingRoom = 16

    // Custom room
    case customRoom = 19

    // Archive
    case archive = 20

    // Thirdparty backup
    case thirdpartyBackup = 21

    // Public room
    case publicRoom = 22

    // Ready form folder
    case readyFormFolder = 25

    // In process form folder
    case inProcessFormFolder = 26

    // Form filling folder done
    case formFillingFolderDone = 27

    // Form filling folder in progress
    case formFillingFolderInProgress = 28

    // Virtual Data Room
    case virtualDataRoom = 29

    // Room templates folder
    case roomTemplates = 30

    // Device folder of documents
    case deviceDocuments = 50

    // Device folder of trash
    case deviceTrash = 51

    // Thirdparty folders
    case nextcloudAll = 101
    case owncloudAll = 102
    case yandexAll = 103
    case webdavAll = 104
    case dropboxAll = 105
    case googledriveAll = 106
    case icloudAll = 107
    case onedriveAll = 108
    case kdriveAll = 109
}

extension ASCFolderType {
    
    var isRoomType: Bool {
        switch self {
        case .customRoom,
                .publicRoom,
                .editingRoom,
                .virtualRooms,
                .virtualDataRoom,
                .fillingFormsRoom,
                .roomTemplates:
            return true
        default:
            return false
        }
    }
}
