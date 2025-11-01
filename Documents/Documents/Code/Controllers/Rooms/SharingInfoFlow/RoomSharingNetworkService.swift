//
//  RoomSharingNetworkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol RoomSharingNetworkServiceProtocol {
    func fetch(room: ASCFolder) async throws -> ([RoomLinkResponseModel], [RoomUsersResponseModel])
    func fetchRoomLinks(room: ASCFolder) async throws -> [RoomLinkResponseModel]
    func fetchRoomUsers(room: ASCFolder) async throws -> [RoomUsersResponseModel]
    func toggleRoomNotifications(room: ASCFolder) async throws -> RoomNotificationsResponceModel
    func duplicateRoom(
        room: ASCFolder,
        pollInterval: UInt64,
        progress: ((Int) -> Void)?
    ) async throws
}

final class RoomSharingNetworkService: RoomSharingNetworkServiceProtocol {
    private let networkService = OnlyofficeApiClient.shared

    // MARK: fetch(room: links+users параллельно)

    func fetch(room: ASCFolder) async throws -> ([RoomLinkResponseModel], [RoomUsersResponseModel]) {
        async let links  = fetchRoomLinks(room: room)
        async let users  = fetchRoomUsers(room: room)
        return try await (links, users)
    }

    // MARK: links

    func fetchRoomLinks(room: ASCFolder) async throws -> [RoomLinkResponseModel] {
        let requestModel = RoomLinksRequestModel(type: 1)

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.getLinks(room: room),
            parameters: requestModel.dictionary
        )

        guard let links = response.result else { throw Errors.emptyResponse }
        return links
    }

    // MARK: users

    func fetchRoomUsers(room: ASCFolder) async throws -> [RoomUsersResponseModel] {
        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.users(room: room)
        )

        guard var users = response.result else { throw Errors.emptyResponse }
        users.forEach { $0.user.accessValue = $0.access }
        return users
    }

    // MARK: notifications

    func toggleRoomNotifications(room: ASCFolder) async throws -> RoomNotificationsResponceModel {
        let requestModel = RoomNotificationsRequestModel(roomsID: room.id, mute: !room.mute)

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.toggleRoomNotifications(room: room),
            parameters: requestModel.dictionary
        )

        guard let model = response.result else { throw Errors.emptyResponse }
        return model
    }

    // MARK: duplicate

    func duplicateRoom(
         room: ASCFolder,
         pollInterval: UInt64 = NSEC_PER_SEC,
         progress: ((Int) -> Void)? = nil
     ) async throws {
         let req = RoomDuplicateRequestModel(folderIds: [room.id], fileIds: [])
         let _ = try await networkService.request(
             endpoint: OnlyofficeAPI.Endpoints.Operations.duplicateRoom,
             parameters: req.dictionary
         )

         // poling
         while true {
             try Task.checkCancellation()
             let progressResult = try await fetchLatestOperationProgress()
             progress?(progressResult)
             if progressResult >= 100 { return }
             try await Task.sleep(nanoseconds: pollInterval)
         }
     }
    
    private func fetchLatestOperationProgress() async throws -> Int {
        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Operations.list
        )
        
        guard let operation = response.result?.first else {
            throw NetworkingError.invalidData
        }
        if let message = operation.error, !message.isEmpty {
            throw StringError(message)
        }
        guard let progress = operation.progress else {
            throw NetworkingError.invalidData
        }
        return progress
    }
}

extension RoomSharingNetworkService {
    enum Errors: Error {
        case emptyResponse
        case invalidData
    }
}
