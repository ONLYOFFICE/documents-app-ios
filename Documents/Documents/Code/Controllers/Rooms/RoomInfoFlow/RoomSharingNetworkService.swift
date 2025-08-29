//
//  RoomSharingNetworkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol RoomSharingNetworkServiceProtocol {
    func fetch(room: ASCFolder, completion: @escaping ([RoomLinkResponseModel], [RoomUsersResponseModel]) -> Void)
    func fetchRoomLinks(room: ASCFolder, completion: @escaping (Result<[RoomLinkResponseModel], Error>) -> Void)
    func fetchRoomUsers(room: ASCFolder, completion: @escaping (Result<[RoomUsersResponseModel], Error>) -> Void)
}

extension RoomSharingNetworkServiceProtocol {
    func fetchRoomUsers(room: ASCFolder) async throws -> [RoomUsersResponseModel] {
        try await withCheckedThrowingContinuation { continuation in
            fetchRoomUsers(room: room) { result in
                continuation.resume(with: result)
            }
        }
    }
}

final class RoomSharingNetworkService: RoomSharingNetworkServiceProtocol {
    private var networkService = OnlyofficeApiClient.shared

    func fetch(room: ASCFolder, completion: @escaping ([RoomLinkResponseModel], [RoomUsersResponseModel]) -> Void) {
        let group = DispatchGroup()
        var links = [RoomLinkResponseModel]()
        var users = [RoomUsersResponseModel]()

        group.enter()
        fetchRoomLinks(room: room) { result in
            if case let .success(loadedLinks) = result {
                links = loadedLinks
            }
            group.leave()
        }

        group.enter()
        fetchRoomUsers(room: room) { result in
            if case let .success(loadedUsers) = result {
                users = loadedUsers
            }
            group.leave()
        }

        group.notify(queue: .main) {
            completion(links, users)
        }
    }

    func fetchRoomLinks(room: ASCFolder, completion: @escaping (Result<[RoomLinkResponseModel], Error>) -> Void) {
        // TODO: - room type

        let requestModel = RoomLinksRequestModel(type: 1)

        networkService.request(OnlyofficeAPI.Endpoints.Rooms.getLinks(room: room), requestModel.dictionary) { response, error in
            guard let links = response?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(RoomSharingNetworkService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(links))
        }
    }

    func fetchRoomUsers(room: ASCFolder, completion: @escaping (Result<[RoomUsersResponseModel], Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Rooms.users(room: room)) { responce, error in
            guard let users = responce?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(RoomSharingNetworkService.Errors.emptyResponse))
                }
                return
            }
            users.forEach { $0.user.accessValue = $0.access }
            completion(.success(users))
        }
    }

    func toggleRoomNotifications(room: ASCFolder, completion: @escaping (Result<RoomNotificationsResponceModel, Error>) -> Void) {
        let requestModel = RoomNotificationsRequestModel(roomsID: room.id, mute: !room.mute)
        networkService.request(OnlyofficeAPI.Endpoints.Rooms.toggleRoomNotifications(room: room), requestModel.dictionary) { responce, error in
            guard let responce = responce?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(RoomSharingNetworkService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(responce))
        }
    }

    func duplicateRoom(room: ASCFolder, handler: ASCEntityProgressHandler?) {
        var cancel = false

        handler?(.begin, 0, nil, nil, &cancel)

        let requestModel = RoomDuplicateRequestModel(folderIds: [room.id], fileIds: [])

        networkService.request(OnlyofficeAPI.Endpoints.Operations.duplicateRoom, requestModel.dictionary) { response, error in
            if let error = error {
                handler?(.error, 1, nil, error, &cancel)
            } else {
                var checkOperation: (() -> Void)?
                checkOperation = {
                    self.networkService.request(OnlyofficeAPI.Endpoints.Operations.list) { result, error in
                        if let error = error {
                            handler?(.error, 1, nil, error, &cancel)
                        } else if let operation = result?.result?.first, let progress = operation.progress {
                            if progress >= 100 {
                                handler?(.end, 1, nil, nil, &cancel)
                            } else {
                                Thread.sleep(forTimeInterval: 1)
                                checkOperation?()
                            }
                        } else {
                            handler?(.error, 1, nil, NetworkingError.invalidData, &cancel)
                        }
                    }
                }
                checkOperation?()
            }
        }
    }
}

extension RoomSharingNetworkService {
    enum Errors: Error {
        case emptyResponse
    }
}
