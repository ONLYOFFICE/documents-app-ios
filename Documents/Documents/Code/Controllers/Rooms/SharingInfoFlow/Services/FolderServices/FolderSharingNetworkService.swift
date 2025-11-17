//
//  FolderSharingNetworkService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 13.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

protocol FolderSharingNetworkServiceProtocol {
    func fetch(folder: ASCFolder) async throws -> ([SharingInfoLinkResponseModel], [RoomUsersResponseModel])
    func fetchLinks(folder: ASCFolder) async throws -> [SharingInfoLinkResponseModel]
    func fetchUsers(folder: ASCFolder) async throws -> [RoomUsersResponseModel]

    func createGeneralLink(folder: ASCFolder) async throws -> SharingInfoLinkModel
    func createLink(folder: ASCFolder) async throws -> SharingInfoLinkModel
}

actor FolderSharingNetworkService: FolderSharingNetworkServiceProtocol {
    private let networkService = OnlyofficeApiClient.shared

    // MARK: fetch(room: links+users)

    func fetch(folder: ASCFolder) async throws -> ([SharingInfoLinkResponseModel], [RoomUsersResponseModel]) {
        async let links = fetchLinks(folder: folder)
        async let users = fetchUsers(folder: folder)
        return try await(links, users)
    }

    // MARK: links

    func fetchLinks(folder: ASCFolder) async throws -> [SharingInfoLinkResponseModel] {
        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Folders.getLinks(folder: folder)
        )

        guard let links = response.result else { throw Errors.emptyResponse }
        return links
    }

    func createGeneralLink(folder: ASCFolder) async throws -> SharingInfoLinkModel {
        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Folders.getLink(folder: folder)
        )
        guard let result = response.result else { throw Errors.emptyResponse }
        return result
    }

    func createLink(folder: ASCFolder) async throws -> SharingInfoLinkModel {
        let requestModel = CreateAndCopyLinkRequestModel(
            access: ASCShareAccess.read.rawValue,
            primary: false,
            expirationDate: nil,
            isInternal: false
        )

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Folders.createLink(folder: folder),
            parameters: requestModel.dictionary
        )
        guard let result = response.result else { throw Errors.emptyResponse }
        return result
    }

    // MARK: users

    func fetchUsers(folder: ASCFolder) async throws -> [RoomUsersResponseModel] {
        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Folders.users(folder: folder)
        )

        guard let users = response.result else { throw Errors.emptyResponse }
        users.forEach { $0.user.accessValue = $0.access }
        return users
    }
}

extension FolderSharingNetworkService {
    enum Errors: Error {
        case emptyResponse
        case invalidData
    }
}
