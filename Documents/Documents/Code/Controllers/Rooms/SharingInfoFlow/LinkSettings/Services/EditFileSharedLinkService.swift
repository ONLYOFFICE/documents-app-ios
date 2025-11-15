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
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        file: ASCFile
    ) async throws {
        let request = RemoveLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType.rawValue,
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
