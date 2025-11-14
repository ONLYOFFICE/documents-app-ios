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
        linkId: String,
        access: Int,
        primary: Bool,
        `internal`: Bool,
        expirationDate: String? = nil,
        denyDownload: Bool,
        password: String? = nil,
        title: String,
        folder: ASCFolder
    ) async throws {
        let request = RemoveLinkRequestModel(
            linkId: linkId,
            access: access,
            primary: primary,
            internal: `internal`,
            expirationDate: expirationDate,
            denyDownload: denyDownload,
            title: title,
            password: password)

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
