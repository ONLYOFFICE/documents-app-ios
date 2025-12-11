//
//  InviteUsersService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol InviteUsersService {
    func loadExternalLink(
        entity: ASCEntity,
        completion: @escaping (Result<ASCSharingOprionsExternalLink?, Error>) -> Void
    )

    func setExternalLinkAccess(
        linkId: String?,
        room: ASCRoom,
        settingAccess: ASCShareAccess,
        completion: @escaping (Result<ASCSharingOprionsExternalLink?, Error>) -> Void
    )
    
    func getInvitationSettings(completion: @escaping(Result<ASCInvitationSettingsResponceModel?, Error>) -> Void)
}

// MARK: - InviteUsersServiceImp

final class InviteUsersServiceImp {
    // MARK: Private vars

    private let networkingRequestManager: NetworkingRequestingProtocol = OnlyofficeApiClient.shared
    private let roomLinkService = RoomSharingLinkAccessNetworkService()
    private lazy var apiWorker = ASCShareSettingsAPIWorkerFactory()
        .get(by: ASCPortalTypeDefinderByCurrentConnection().definePortalType())
}

// MARK: - InviteUsersService

extension InviteUsersServiceImp: InviteUsersService {
    func loadExternalLink(entity: ASCEntity, completion: @escaping (Result<ASCSharingOprionsExternalLink?, Error>) -> Void) {
        guard let apiRequest = apiWorker.makeApiRequest(entity: entity, for: .get)
        else {
            completion(.failure(NetworkingError.unknown(error: nil)))
            return
        }

        var params: [String: Any] = apiWorker.convertToParams(entities: [entity]) ?? [:]
        params["filterType"] = 1

        networkingRequestManager.request(apiRequest, params) { response, error in
            var externalLink: ASCSharingOprionsExternalLink?
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            if let sharedItems = response?.result {
                if let linkItem = sharedItems.first(where: { $0.link != nil }),
                   let link = linkItem.link,
                   let shareId = linkItem.sharedTo?["id"] as? String
                {
                    externalLink = .init(id: shareId, link: link, isLocked: linkItem.locked, access: linkItem.access)
                }
            }
            completion(.success(externalLink))
        }
    }

    func setExternalLinkAccess(
        linkId: String?,
        room: ASCRoom,
        settingAccess: ASCShareAccess
    ) async throws -> ASCSharingOprionsExternalLink? {
        if let linkId, settingAccess == .deny || settingAccess == .none {
            try await roomLinkService.removeLink(
                id: linkId,
                title: "Invite",
                linkType: .invitation,
                password: nil,
                room: room
            )
            return nil
        } else {
            let model = try await roomLinkService.changeOrCreateLink(
                id: linkId,
                title: "Invite",
                access: settingAccess.rawValue,
                expirationDate: nil,
                linkType: .invitation,
                denyDownload: false,
                password: nil,
                isInternal: false,
                room: room
            )
            return ASCSharingOprionsExternalLink(
                id: model.linkInfo.id,
                link: model.linkInfo.shareLink,
                isLocked: model.isLocked,
                access: model.access
            )
        }
    }
    
    func getInvitationSettings(completion: @escaping(Result<ASCInvitationSettingsResponceModel?, Error>) -> Void) {
        networkingRequestManager.request(OnlyofficeAPI.Endpoints.Sharing.getInvitationSettings(), nil) { result, error in
            if let result = result?.result {
                completion(.success(result))
            } else if let error {
                completion(.failure(error))
            }
        }
    }
}
