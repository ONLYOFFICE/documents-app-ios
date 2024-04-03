//
//  RoomSharingNetworkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol RoomSharingNetworkServiceProtocol {
    func fetch(room: ASCFolder, completion: @escaping ([RoomLinkResponceModel], [RoomUsersResponceModel]) -> Void)
    func fetchRoomLinks(room: ASCFolder, completion: @escaping (Result<[RoomLinkResponceModel], Error>) -> Void)
    func fetchRoomUsers(room: ASCFolder, completion: @escaping (Result<[RoomUsersResponceModel], Error>) -> Void)
}

final class RoomSharingNetworkService: RoomSharingNetworkServiceProtocol {
    private var networkService = OnlyofficeApiClient.shared

    func fetch(room: ASCFolder, completion: @escaping ([RoomLinkResponceModel], [RoomUsersResponceModel]) -> Void) {
        let group = DispatchGroup()
        var links = [RoomLinkResponceModel]()
        var users = [RoomUsersResponceModel]()

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

    func fetchRoomLinks(room: ASCFolder, completion: @escaping (Result<[RoomLinkResponceModel], Error>) -> Void) {
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

    func fetchRoomUsers(room: ASCFolder, completion: @escaping (Result<[RoomUsersResponceModel], Error>) -> Void) {
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
    
    func disableNotifications(room: ASCFolder, completion: @escaping (Result<RoomNotificationsResponceModel, Error>) -> Void) {
        let requestModel = RoomNotificationsRequestModel(roomsID: Int(room.id)!, mute: room.mute)
        networkService.request(OnlyofficeAPI.Endpoints.Rooms.disableNotifications(room: room), requestModel.dictionary) { responce, error in
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
}

extension RoomSharingNetworkService {
    enum Errors: Error {
        case emptyResponse
    }
}
