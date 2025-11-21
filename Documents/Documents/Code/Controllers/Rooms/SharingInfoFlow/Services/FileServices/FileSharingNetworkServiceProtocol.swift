//
//  FileSharingNetworkServiceProtocol.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol FileSharingNetworkServiceProtocol {
    func fetch(file: ASCFile) async throws -> ([SharingInfoLinkResponseModel], [RoomUsersResponseModel])
    func fetchLinks(file: ASCFile) async throws -> [SharingInfoLinkResponseModel]
    func fetchUsers(file: ASCFile) async throws -> [RoomUsersResponseModel]

    func createGeneralLink(file: ASCFile) async throws -> SharingInfoLinkModel
    func createLink(file: ASCFile, access: ASCShareAccess) async throws -> SharingInfoLinkModel
}

extension FileSharingNetworkServiceProtocol {
    func createLink(file: ASCFile, access: ASCShareAccess? = .some(.read)) async throws -> SharingInfoLinkModel {
        try await createLink(file: file, access: access)
    }
}

actor FileSharingNetworkService: FileSharingNetworkServiceProtocol {
    private let networkService = OnlyofficeApiClient.shared

    // MARK: fetch(room: links+users)

    func fetch(file: ASCFile) async throws -> ([SharingInfoLinkResponseModel], [RoomUsersResponseModel]) {
        async let links = fetchLinks(file: file)
        async let users = fetchUsers(file: file)
        return try await(links, users)
    }

    // MARK: links

    func fetchLinks(file: ASCFile) async throws -> [SharingInfoLinkResponseModel] {
        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Files.getLinks(file: file)
        )

        guard let links = response.result else { throw Errors.emptyResponse }
        return links
    }

    func createGeneralLink(file: ASCFile) async throws -> SharingInfoLinkModel {
        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Files.getLink(file: file)
        )
        guard let result = response.result else { throw Errors.emptyResponse }
        return result
    }

    func createLink(file: ASCFile, access: ASCShareAccess) async throws -> SharingInfoLinkModel {
        let requestModel = CreateAndCopyLinkRequestModel(
            access: access.rawValue,
            primary: false,
            expirationDate: nil,
            isInternal: false
        )

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Files.createLink(file: file),
            parameters: requestModel.dictionary
        )
        guard let result = response.result else { throw Errors.emptyResponse }
        return result
    }

    // MARK: users

    func fetchUsers(file: ASCFile) async throws -> [RoomUsersResponseModel] {
        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Sharing.fileUsers(file: file, method: .get)
        )

        guard let users = response.result else { throw Errors.emptyResponse }
        users.forEach { $0.user.accessValue = $0.access }
        return users
    }
}

extension FileSharingNetworkService {
    enum Errors: Error {
        case emptyResponse
        case invalidData
    }
}
