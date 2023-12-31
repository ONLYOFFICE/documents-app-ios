//
//  RoomSharingLinkAccessService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28/12/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol RoomSharingLinkAccessService {
    func removeLink(
        id: String,
        title: String,
        linkType: Int,
        password: String?,
        room: ASCRoom,
        completion: @escaping (Error?) -> Void
    )

    func changeOrCreateLink(
        id: String?,
        title: String,
        access: Int,
        expirationDate: String?,
        linkType: Int,
        denyDownload: Bool,
        password: String?,
        room: ASCRoom,
        completion: @escaping (Result<RoomLinkResponceModel, Error>) -> Void
    )
}

final class RoomSharingLinkAccessNetworkService: RoomSharingLinkAccessService {
    private var networkService = OnlyofficeApiClient.shared

    func removeLink(
        id: String,
        title: String,
        linkType: Int,
        password: String?,
        room: ASCRoom,
        completion: @escaping (Error?) -> Void
    ) {
        let requestModel = RoomRemoveLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType,
            password: password
        )

        networkService.request(OnlyofficeAPI.Endpoints.Rooms.removeLink(folder: room), requestModel.dictionary) { response, error in
            DispatchQueue.main.async {
                guard response != nil, error == nil else {
                    completion(error ?? RoomSharingLinkAccessNetworkService.Errors.emptyResponse)
                    return
                }
                completion(nil)
            }
        }
    }

    func changeOrCreateLink(
        id: String?,
        title: String,
        access: Int,
        expirationDate: String?,
        linkType: Int,
        denyDownload: Bool,
        password: String?,
        room: ASCRoom,
        completion: @escaping (Result<RoomLinkResponceModel, Error>) -> Void
    ) {
        let requestModel = RoomLinkRequestModel(
            linkId: id,
            title: title,
            access: access,
            expirationDate: expirationDate,
            linkType: linkType,
            denyDownload: denyDownload,
            password: password
        )

        networkService.request(OnlyofficeAPI.Endpoints.Rooms.setLinks(folder: room), requestModel.dictionary) { response, error in
            DispatchQueue.main.async {
                guard let result = response?.result else {
                    completion(.failure(error ?? RoomSharingLinkAccessNetworkService.Errors.emptyResponse))
                    return
                }

                completion(.success(result))
            }
        }
    }
}

extension RoomSharingLinkAccessNetworkService {
    enum Errors: Error {
        case emptyResponse
    }
}
