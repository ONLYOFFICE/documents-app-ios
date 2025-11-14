//
//  EditFileSharedLinkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 13.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//


final class EditFileSharedLinkService {
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
        file: ASCFile
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
            endpoint: OnlyofficeAPI.Endpoints.Files.deleteLink(file: file),
            parameters: request.dictionary
        )
        guard response.statusCode != nil else { throw Errors.emptyResponse }
    }
}


extension EditFileSharedLinkService {
    enum Errors: Error {
        case emptyResponse
    }
}
