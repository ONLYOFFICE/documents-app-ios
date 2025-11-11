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
        room: ASCRoom
    ) async throws

    func revokeLink(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        room: ASCRoom,
        denyDownload: Bool
    ) async throws

    func changeOrCreateLink(
        id: String?,
        title: String,
        access: Int,
        expirationDate: String?,
        linkType: ASCShareLinkType,
        denyDownload: Bool,
        password: String?,
        room: ASCRoom
    ) async throws -> SharingInfoLinkModel

    func createLink(
        title: String,
        access: Int,
        expirationDate: String?,
        linkType: ASCShareLinkType,
        denyDownload: Bool,
        password: String?,
        room: ASCRoom
    ) async throws -> SharingInfoLinkModel

    func createGeneralLink(
        room: ASCRoom
    ) async throws -> SharingInfoLinkModel
}

// MARK: - Defaults

extension RoomSharingLinkAccessService {
    func createLink(
        title: String,
        access: Int = .defaultAccsessForLink,
        expirationDate: String? = nil,
        linkType: ASCShareLinkType,
        denyDownload: Bool = false,
        password: String? = nil,
        room: ASCRoom
    ) async throws -> SharingInfoLinkModel {
        try await changeOrCreateLink(
            id: nil,
            title: title,
            access: access,
            expirationDate: expirationDate,
            linkType: linkType,
            denyDownload: denyDownload,
            password: password,
            room: room
        )
    }
}

// MARK: - Implementation

final class RoomSharingLinkAccessNetworkService: RoomSharingLinkAccessService {
    private let networkService = OnlyofficeApiClient.shared

    func removeLink(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        room: ASCRoom
    ) async throws {
        let request = RoomRemoveLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType.rawValue,
            password: password
        )

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.removeLink(folder: room),
            parameters: request.dictionary
        )
        guard response.statusCode != nil else { throw Errors.emptyResponse }
    }

    func revokeLink(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?,
        room: ASCRoom,
        denyDownload: Bool
    ) async throws {
        let request = RoomRevokeLinkRequestModel(
            linkId: id,
            title: title,
            access: ASCShareAccess.none.rawValue,
            linkType: linkType.rawValue,
            password: password,
            denyDownload: denyDownload
        )

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.revokeLink(folder: room),
            parameters: request.dictionary
        )
        guard response.statusCode != nil else { throw Errors.emptyResponse }
    }

    func changeOrCreateLink(
        id: String?,
        title: String,
        access: Int,
        expirationDate: String?,
        linkType: ASCShareLinkType,
        denyDownload: Bool,
        password: String?,
        room: ASCRoom
    ) async throws -> SharingInfoLinkModel {
        let request = RoomLinkRequestModel(
            linkId: id,
            title: title,
            access: access,
            expirationDate: expirationDate,
            linkType: linkType.rawValue,
            denyDownload: denyDownload,
            password: password
        )

        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.setLinks(folder: room),
            parameters: request.dictionary
        )

        guard let result = response.result else { throw Errors.emptyResponse }
        return result
    }

    func createGeneralLink(
        room: ASCRoom
    ) async throws -> SharingInfoLinkModel {
        let response = try await networkService.request(
            endpoint: OnlyofficeAPI.Endpoints.Rooms.getLink(folder: room)
        )
        guard let result = response.result else { throw Errors.emptyResponse }
        return result
    }
}

extension RoomSharingLinkAccessNetworkService {
    enum Errors: Error {
        case emptyResponse
        case invalidData
    }
}

private extension Int {
    static let defaultAccsessForLink = ASCShareAccess.read.rawValue
}
