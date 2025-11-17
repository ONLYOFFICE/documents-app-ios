//
//  EditRoomSharedLinkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 13.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

final class EditRoomSharedLinkService {
    private let networkService = OnlyofficeApiClient.shared

    func delete(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        room: ASCRoom
    ) async throws {
        let request = RemoveLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType.rawValue,
            password: password
        )

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.removeLink(folder: room),
            parameters: request.dictionary
        )
        guard response.statusCode != nil else { throw Errors.emptyResponse }
    }

    func revokeLink(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        room: ASCRoom,
        denyDownload: Bool
    ) async throws {
        let request = RevokeLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType.rawValue,
            password: password,
            denyDownload: denyDownload
        )

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.revokeLink(folder: room),
            parameters: request.dictionary
        )
        guard response.statusCode != nil else { throw Errors.emptyResponse }
    }

    func editRoomLink(
        id: String?,
        title: String,
        access: Int,
        expirationDate: String?,
        linkType: ASCShareLinkType,
        denyDownload: Bool,
        password: String?,
        isInternal: Bool,
        room: ASCRoom
    ) async throws -> SharingInfoLinkModel {
        let request = LinkRequestModel(
            linkId: id,
            title: title,
            access: access,
            expirationDate: expirationDate,
            linkType: linkType.rawValue,
            denyDownload: denyDownload,
            internal: isInternal,
            password: password
        )

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.setLinks(folder: room),
            parameters: request.dictionary
        )

        guard let result = response.result else { throw Errors.emptyResponse }
        return result
    }
}

extension EditRoomSharedLinkService {
    enum Errors: Error {
        case emptyResponse
        case invalidData
    }
}
