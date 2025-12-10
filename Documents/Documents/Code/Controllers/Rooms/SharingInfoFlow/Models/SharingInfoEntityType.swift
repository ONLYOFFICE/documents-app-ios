//
//  SharingInfoEntityType.swift
//  Documents
//
//  Created by Pavel Chernyshev on 11.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

enum SharingInfoEntityType {
    case room(ASCRoom)
    case file(ASCFile)
    case folder(ASCFolder)
}

extension SharingInfoEntityType {
    var editSharedLinkEntityType: EditSharedLinkEntityType {
        switch self {
        case let .room(room):
            .room(room)
        case let .file(file):
            .file(file)
        case let .folder(folder):
            .folder(folder)
        }
    }
}
