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
        linkType: ASCShareLinkType,
        password: String?,
        room: ASCRoom,
        completion: @escaping (Error?) -> Void
    )

    func revokeLink(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        room: ASCRoom,
        denyDownload: Bool,
        completion: @escaping (Error?) -> Void
    )

    func changeOrCreateLink(
        id: String?,
        title: String,
        access: Int,
        expirationDate: String?,
        linkType: ASCShareLinkType,
        denyDownload: Bool,
        password: String?,
        room: ASCRoom,
        completion: @escaping (Result<RoomLinkResponceModel, Error>) -> Void
    )

    func createLink(
        title: String,
        access: Int,
        expirationDate: String?,
        linkType: ASCShareLinkType,
        denyDownload: Bool,
        password: String?,
        room: ASCRoom,
        completion: @escaping (Result<RoomLinkResponceModel, Error>) -> Void
    )

    func createGeneralLink(
        room: ASCRoom,
        completion: @escaping (Result<RoomLinkResponceModel, Error>) -> Void
    )
}

extension RoomSharingLinkAccessService {
    func createLink(
        title: String,
        access: Int = .defaultAccsessForLink,
        expirationDate: String? = nil,
        linkType: ASCShareLinkType,
        denyDownload: Bool = false,
        password: String? = nil,
        room: ASCRoom,
        completion: @escaping (Result<RoomLinkResponceModel, Error>) -> Void
    ) {
        changeOrCreateLink(
            id: nil,
            title: title,
            access: access,
            expirationDate: expirationDate,
            linkType: linkType,
            denyDownload: denyDownload,
            password: password,
            room: room,
            completion: completion
        )
    }
}

final class RoomSharingLinkAccessNetworkService: RoomSharingLinkAccessService {
    private var networkService = OnlyofficeApiClient.shared

    func removeLink(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        room: ASCRoom,
        completion: @escaping (Error?) -> Void
    ) {
        let requestModel = RoomRemoveLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType.rawValue,
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

    func revokeLink(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        room: ASCRoom,
        denyDownload: Bool,
        completion: @escaping (Error?) -> Void
    ) {
        let requestModel = RoomRevokeLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType.rawValue,
            password: password,
            denyDownload: denyDownload
        )

        networkService.request(OnlyofficeAPI.Endpoints.Rooms.revokeLink(folder: room), requestModel.dictionary) { response, error in
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
        linkType: ASCShareLinkType,
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
            linkType: linkType.rawValue,
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

    func createGeneralLink(
        room: ASCRoom,
        completion: @escaping (Result<RoomLinkResponceModel, Error>) -> Void
    ) {
        networkService.request(OnlyofficeAPI.Endpoints.Rooms.getLink(folder: room)) { response, error in
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

private extension Int {
    static let defaultAccsessForLink = ASCShareAccess.read.rawValue
}
