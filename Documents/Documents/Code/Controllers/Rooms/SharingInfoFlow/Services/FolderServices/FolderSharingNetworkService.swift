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
        let requestModel = RoomLinksRequestModel(type: 1)

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Folders.getLinks(folder: folder),
            parameters: requestModel.dictionary
        )

        guard let links = response.result else { throw Errors.emptyResponse }
        return links
    }

    // MARK: users

    func fetchUsers(folder: ASCFolder) async throws -> [RoomUsersResponseModel] {
        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Folders.users(folder: folder)
        )

        guard var users = response.result else { throw Errors.emptyResponse }
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
