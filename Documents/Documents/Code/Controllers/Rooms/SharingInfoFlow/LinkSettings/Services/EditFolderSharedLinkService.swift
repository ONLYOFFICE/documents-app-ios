//
//  EditFolderSharedLinkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 13.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

final class EditFolderSharedLinkService {
    private let networkService = OnlyofficeApiClient.shared
    
    func delete(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        folder: ASCFolder
    ) async throws {
        let request = RemoveLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType.rawValue,
            password: password
        )

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Folders.deleteLink(folder: folder),
            parameters: request.dictionary
        )
        guard response.statusCode != nil else { throw Errors.emptyResponse }
    }
    
    func revoke(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        room: ASCRoom,
        denyDownload: Bool,
        folder: ASCFolder
    ) async throws {
        let request = RevokeLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType.rawValue,
            password: password,
            denyDownload: denyDownload)

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Folders.deleteLink(folder: folder),
            parameters: request.dictionary
        )
        guard response.statusCode != nil else { throw Errors.emptyResponse }
    }
}

extension EditFolderSharedLinkService {
    enum Errors: Error {
        case emptyResponse
    }
}
