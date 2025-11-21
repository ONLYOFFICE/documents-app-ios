//
//  SharingInfoLinkAccessService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 05.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

// MARK: - Protocol

protocol SharingInfoLinkAccessService {
    func fetchLinksAndUsers() async throws -> ([SharingInfoLinkResponseModel], [RoomUsersResponseModel])

    func createGeneralLink() async throws -> SharingInfoLinkModel

    func createLink(
        title: String,
        linkType: ASCShareLinkType
    ) async throws -> SharingInfoLinkModel

    func removeLink(
        id: String,
        title: String,
        denyDownload: Bool,
        linkType: ASCShareLinkType,
        password: String?
    ) async throws

    func changeAccess(for id: String, newAccess: ASCShareAccess) async throws
}

// MARK: - Implementation

actor SharingInfoLinkAccessServiceImp {
    private let entityType: SharingInfoEntityType

    // MARK: Dependencies

    private let roomSharingLinkAccesskService: RoomSharingLinkAccessService
    private let folderSharingNetworkService: FolderSharingNetworkServiceProtocol
    private let fileSharingNetworkService: FileSharingNetworkServiceProtocol

    private let sharingRoomNetworkService: RoomSharingNetworkServiceProtocol
    private let editSharedLinkService: EditSharedLinkServiceProtocol

    // MARK: Init

    init(
        entityType: SharingInfoEntityType,
        roomSharingLinkAccesskService: RoomSharingLinkAccessService,
        folderSharingNetworkService: FolderSharingNetworkServiceProtocol,
        fileSharingNetworkService: FileSharingNetworkServiceProtocol,
        sharingRoomNetworkService: RoomSharingNetworkServiceProtocol,
        editSharedLinkService: EditSharedLinkServiceProtocol
    ) {
        self.entityType = entityType
        self.roomSharingLinkAccesskService = roomSharingLinkAccesskService
        self.folderSharingNetworkService = folderSharingNetworkService
        self.fileSharingNetworkService = fileSharingNetworkService
        self.sharingRoomNetworkService = sharingRoomNetworkService
        self.editSharedLinkService = editSharedLinkService
    }
}

// MARK: - SharingInfoLinkAccessServiceImp

extension SharingInfoLinkAccessServiceImp: SharingInfoLinkAccessService {
    func fetchLinksAndUsers() async throws -> ([SharingInfoLinkResponseModel], [RoomUsersResponseModel]) {
        switch entityType {
        case let .room(room):
            try await sharingRoomNetworkService.fetch(room: room)
        case let .file(file):
            try await fileSharingNetworkService.fetch(file: file)
        case let .folder(folder):
            try await folderSharingNetworkService.fetch(folder: folder)
        }
    }

    func createGeneralLink() async throws -> SharingInfoLinkModel {
        switch entityType {
        case let .room(room):
            try await roomSharingLinkAccesskService.createGeneralLink(room: room)
        case let .file(file):
            try await fileSharingNetworkService.createGeneralLink(file: file)
        case let .folder(folder):
            try await folderSharingNetworkService.createGeneralLink(folder: folder)
        }
    }

    func createLink(
        title: String,
        linkType: ASCShareLinkType
    ) async throws -> SharingInfoLinkModel {
        switch entityType {
        case let .room(room):
            return try await roomSharingLinkAccesskService.createLink(
                title: title,
                linkType: linkType,
                room: room
            )
        case let .file(file):
            let access: ASCShareAccess = file.isForm ? .editing : .read
            return try await fileSharingNetworkService.createLink(file: file, access: access)
        case let .folder(folder):
            return try await folderSharingNetworkService.createLink(folder: folder)
        }
    }

    func removeLink(
        id: String,
        title: String,
        denyDownload: Bool,
        linkType: ASCShareLinkType,
        password: String?
    ) async throws {
        try await editSharedLinkService.revoke(
            id: id,
            denyDownload: denyDownload,
            title: title,
            linkType: linkType,
            password: password
        )
    }

    func changeAccess(for id: String, newAccess: ASCShareAccess) async throws {
        let response: OnlyofficeResponseBase = switch entityType {
        case let .room(room):
            try await OnlyofficeApiClient.shared.request(
                endpoint: OnlyofficeAPI.Endpoints.Sharing.inviteRequest(folder: room),
                parameters: OnlyofficeInviteRequestModel(
                    notify: false,
                    invitations: [OnlyofficeInviteItemRequestModel(id: id, access: newAccess)]
                ).toJSON()
            )
        case let .file(file):
            try await OnlyofficeApiClient.shared.request(
                endpoint: OnlyofficeAPI.Endpoints.Sharing.fileShare(file: file, method: .put),
                parameters: OnlyofficeShareRequestModel(
                    share: [OnlyofficeShareItemRequestModel(shareTo: id, access: newAccess)]
                ).toJSON()
            )
        case let .folder(folder):
            try await OnlyofficeApiClient.shared.request(
                endpoint: OnlyofficeAPI.Endpoints.Sharing.folder(folder: folder, method: .put),
                parameters: OnlyofficeShareRequestModel(
                    share: [OnlyofficeShareItemRequestModel(shareTo: id, access: newAccess)]
                ).toJSON()
            )
        }
        guard let statusCode = response.statusCode, (200 ..< 300).contains(statusCode) else {
            throw NetworkingError.invalidData
        }
    }
}
