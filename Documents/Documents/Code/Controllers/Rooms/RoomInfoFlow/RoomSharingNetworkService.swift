//
//  RoomSharingNetworkService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol RoomSharingNetworkServiceProtocol {
    func fetchRoomLinks(room: ASCFolder, completion: @escaping (Result<[RoomLinkResponceModel], Error>) -> Void)
    func fetchRoomUsers(room: ASCFolder, completion: @escaping (Result<[RoomUsersResponceModel], Error>) -> Void)
}

final class RoomSharingNetworkService: RoomSharingNetworkServiceProtocol {
    private var networkService = OnlyofficeApiClient.shared

    func fetchRoomUsers(room: ASCFolder, completion: @escaping (Result<[RoomUsersResponceModel], Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Rooms.users(room: room)) { responce, error in
            guard let users = responce?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NetworkSharingRoomService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(users))
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
                    completion(.failure(NetworkSharingRoomService.Errors.emptyResponse))
                }
                return
            }
            completion(.success(links))
        }
    }
}

extension RoomSharingNetworkService {
    enum Errors: Error {
        case emptyResponse
    }
}
