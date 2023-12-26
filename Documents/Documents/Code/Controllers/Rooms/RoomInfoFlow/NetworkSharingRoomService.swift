//
//  NetworkSharingRoomService.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol NetworkSharingRoomServiceProtocol {
    
    func fetchRoomLinks(room: ASCFolder, completion: @escaping (Result<[RoomLinkResponceModel], Error>) -> Void)
}

final class NetworkSharingRoomService: NetworkSharingRoomServiceProtocol {
    
    private var networkService = OnlyofficeApiClient.shared
    
    func fetchRoomLinks(room: ASCFolder, completion: @escaping (Result<[RoomLinkResponceModel], Error>) -> Void) {
        //TODO: - room type

        let requestModel = RoomLinksRequestModel(type: 1)

        networkService.request(OnlyofficeAPI.Endpoints.Rooms.getLinks(room: room), requestModel.dictionary) { response, error in

            guard let links = response?.result else {
                if let error{
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

extension NetworkSharingRoomService {
    
    enum Errors: Error {
        case emptyResponse
    }
}
