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
        case .room(let room):
            .room(room)
        case .file(let file):
            .file(file)
        case .folder(let folder):
            .folder(folder)
        }
    }
}
