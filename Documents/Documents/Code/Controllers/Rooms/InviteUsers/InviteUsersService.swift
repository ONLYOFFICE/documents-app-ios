//
//  InviteUsersService.swift
//  Documents-opensource
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
        settingAccess: ASCShareAccess,
        completion: @escaping (Result<ASCSharingOprionsExternalLink?, Error>) -> Void
    ) {
        if let linkId, settingAccess == .deny || settingAccess == .none {
            roomLinkService.removeLink(
                id: linkId,
                title: "Invite",
                linkType: .invitation,
                password: nil,
                room: room
            ) { error in
                if let error {
                    completion(
                        .failure(error)
                    )
                } else {
                    completion(.success(nil))
                }
            }
        } else {
            roomLinkService.changeOrCreateLink(
                id: linkId,
                title: "Invite",
                access: settingAccess.rawValue,
                expirationDate: nil,
                linkType: .invitation,
                denyDownload: false,
                password: nil,
                room: room
            ) { result in
                switch result {
                case let .success(model):
                    completion(
                        .success(
                            ASCSharingOprionsExternalLink(
                                id: model.linkInfo.id,
                                link: model.linkInfo.shareLink,
                                isLocked: model.isLocked,
                                access: model.access
                            )
                        )
                    )
                case let .failure(error):
                    completion(
                        .failure(error)
                    )
                }
            }
        }
    }
}
