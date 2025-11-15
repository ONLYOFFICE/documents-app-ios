//
//  EditSharedLinkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 13.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

protocol EditSharedLinkServiceProtocol: AnyObject {
    func delete(id: String, title: String, linkType: ASCShareLinkType, password: String?) async throws
    func revoke(id: String, denyDownload: Bool, title: String, linkType: ASCShareLinkType, password: String?) async throws
    func save()
}

class EditSharedLinkService: EditSharedLinkServiceProtocol {
    private var entity: EditSharedLinkEntityType
    
    private lazy var editFileSharedLinkService: EditFileSharedLinkService?  = EditFileSharedLinkService()
    private lazy var editFolderSharedLinkService: EditFolderSharedLinkService? = EditFolderSharedLinkService()
    private lazy var editRoomSharedLinkService: EditRoomSharedLinkService? = EditRoomSharedLinkService()
    
    init(entity: EditSharedLinkEntityType) {
        self.entity = entity
    }
    
    func delete(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?
    ) async throws {
        switch entity {
        case let .room(room):
            try await editRoomSharedLinkService?.delete(id: id, title: title, linkType: linkType, password: password, room: room)
        case let .folder(folder):
            try await editFolderSharedLinkService?.delete(id: id, title: title, linkType: linkType, password: password, folder: folder)
        case let .file(file):
            try await editFileSharedLinkService?.delete(
                id: id, title: title, linkType: linkType, password: password, file: file)
        }
    }
    
    func revoke(
        id: String,
        denyDownload: Bool,
        title: String,
        linkType: ASCShareLinkType,
        password: String?
    ) async throws  {
        switch entity {
        case let .room(room):
            try await editRoomSharedLinkService?.revokeLink(id: id, title: title, linkType: linkType, password: password, room: room, denyDownload: denyDownload)
        case let .folder(folder):
            try await editFolderSharedLinkService?.delete(id: id, title: title, linkType: linkType, password: password, folder: folder)
        case let .file(file):
            return
            //editFileSharedLinkService?.delete(file: file)
        }
    }
    
    func save() {
        
    }
}

extension EditSharedLinkService {
    enum Errors: Error {
        case emptyResponse
        case invalidData
    }
}
