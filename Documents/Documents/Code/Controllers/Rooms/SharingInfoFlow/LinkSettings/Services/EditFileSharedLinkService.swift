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
    
    func revoke(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        denyDownload: Bool,
        file: ASCFile
    ) async throws {
        let request = RevokeLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType.rawValue,
            password: password,
            denyDownload: denyDownload)

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Files.deleteLink(file: file),
            parameters: request.dictionary
        )
        guard response.statusCode != nil else { throw Errors.emptyResponse }
    }
    
    func editFileLink(
        id: String?,
        title: String,
        access: Int,
        expirationDate: String?,
        linkType: ASCShareLinkType,
        denyDownload: Bool,
        password: String?,
        file: ASCFile
    ) async throws -> SharingInfoLinkModel {
        let request = LinkRequestModel(
            linkId: id,
            title: title,
            access: access,
            expirationDate: expirationDate,
            linkType: linkType.rawValue,
            denyDownload: denyDownload,
            password: password
        )

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Files.setLinks(file: file),
            parameters: request.dictionary
        )

        guard let result = response.result else { throw Errors.emptyResponse }
        return result
    }
}


extension EditFileSharedLinkService {
    enum Errors: Error {
        case emptyResponse
    }
}
