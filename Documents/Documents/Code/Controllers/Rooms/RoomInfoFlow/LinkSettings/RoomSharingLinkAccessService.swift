//
//  RoomSharingLinkAccessService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28/12/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol RoomSharingLinkAccessService {
    func removeLink(id: String, room: ASCRoom, completion: @escaping (Error?) -> Void)
    func createLink(
        title: String,
        access: Int,
        expirationDate: String,
        linkType: Int,
        denyDownload: Bool,
        room: ASCRoom,
        completion: @escaping (Result<RoomLinkResponceModel, Error>) -> Void
    )
}

final class RoomSharingLinkAccessNetworkService: RoomSharingLinkAccessService {
    private var networkService = OnlyofficeApiClient.shared

    func removeLink(id: String, room: ASCRoom, completion: @escaping (Error?) -> Void) {
        let requestModel = RoomLinkRequestModel(
            linkId: id,
            title: "",
            access: 0,
            expirationDate: "",
            linkType: 0,
            denyDownload: true
        )

        networkService.request(OnlyofficeAPI.Endpoints.Rooms.setLinks(folder: room), requestModel.dictionary) { response, error in
            completion(error)
        }
    }

    func createLink(
        title: String,
        access: Int,
        expirationDate: String,
        linkType: Int,
        denyDownload: Bool,
        room: ASCRoom,
        completion: @escaping (Result<RoomLinkResponceModel, Error>) -> Void
    ) {
        let requestModel = RoomLinkRequestModel(
            title: title,
            access: access,
            expirationDate: expirationDate,
            linkType: linkType,
            denyDownload: denyDownload
        )

        networkService.request(OnlyofficeAPI.Endpoints.Rooms.setLinks(folder: room), requestModel.dictionary) { response, error in
            guard let result = response?.result else {
                completion(.failure(error ?? RoomSharingLinkAccessNetworkService.Errors.emptyResponse))
                return
            }
            completion(.success(result))
        }
    }
}

extension RoomSharingLinkAccessNetworkService {
    enum Errors: Error {
        case emptyResponse
    }
}
