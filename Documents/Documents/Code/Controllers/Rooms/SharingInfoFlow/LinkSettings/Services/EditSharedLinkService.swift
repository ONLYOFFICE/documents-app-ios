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
    func editLink(id: String?, title: String, access: Int, expirationDate: String?, linkType: ASCShareLinkType, denyDownload: Bool, password: String?, isInternal: Bool) async throws -> SharingInfoLinkModel
}

class EditSharedLinkService: EditSharedLinkServiceProtocol {
    private var entity: EditSharedLinkEntityType

    private lazy var editFileSharedLinkService: EditFileSharedLinkService? = EditFileSharedLinkService()
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
                id: id, title: title, linkType: linkType, password: password, file: file
            )
        }
    }

    func revoke(
        id: String,
        denyDownload: Bool,
        title: String,
        linkType: ASCShareLinkType,
        password: String?
    ) async throws {
        switch entity {
        case let .room(room):
            try await editRoomSharedLinkService?.revokeLink(id: id, title: title, linkType: linkType, password: password, room: room, denyDownload: denyDownload)
        case let .folder(folder):
            try await editFolderSharedLinkService?.delete(id: id, title: title, linkType: linkType, password: password, folder: folder)
        case let .file(file):
            try await editFileSharedLinkService?.revoke(id: id, title: title, linkType: linkType, password: password, denyDownload: denyDownload, file: file)
        }
    }

    func editLink(
        id: String?,
        title: String,
        access: Int,
        expirationDate: String?,
        linkType: ASCShareLinkType,
        denyDownload: Bool,
        password: String?,
        isInternal: Bool
    ) async throws -> SharingInfoLinkModel {
        switch entity {
        case let .room(room):
            let result = try await editRoomSharedLinkService?.editRoomLink(
                id: id,
                title: title,
                access: access,
                expirationDate: expirationDate,
                linkType: linkType,
                denyDownload: denyDownload,
                password: password,
                isInternal: isInternal,
                room: room
            )
            guard let result else {
                throw Errors.invalidData
            }
            return result
        case let .folder(folder):
            let result = try await editFolderSharedLinkService?.editFolderLink(
                id: id,
                title: title,
                access: access,
                expirationDate: expirationDate,
                linkType: linkType,
                denyDownload: denyDownload,
                password: password,
                isInternal: isInternal,
                folder: folder
            )
            guard let result else {
                throw Errors.invalidData
            }
            return result
        case let .file(file):
            let result = try await editFileSharedLinkService?.editFileLink(
                id: id,
                title: title,
                access: access,
                expirationDate: expirationDate,
                linkType: linkType,
                denyDownload: denyDownload,
                password: password,
                isInternal: isInternal,
                file: file
            )
            guard let result else {
                throw Errors.invalidData
            }
            return result
        }
    }
}

extension EditSharedLinkService {
    enum Errors: Error {
        case emptyResponse
        case invalidData
    }
}
