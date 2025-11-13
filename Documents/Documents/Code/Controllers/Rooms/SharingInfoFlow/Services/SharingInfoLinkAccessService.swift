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
        linkType: ASCShareLinkType,
        password: String?
    ) async throws
}

// MARK: - Implementation

actor SharingInfoLinkAccessServiceImp {
    private let entityType: SharingInfoEntityType

    // MARK: Dependencies

    private let roomSharingLinkAccesskService: RoomSharingLinkAccessService
    private let folderSharingNetworkService: FolderSharingNetworkServiceProtocol
    
    private let sharingRoomNetworkService: RoomSharingNetworkServiceProtocol

    // MARK: Init

    init(
        entityType: SharingInfoEntityType,
        roomSharingLinkAccesskService: RoomSharingLinkAccessService,
        folderSharingNetworkService: FolderSharingNetworkServiceProtocol,
        sharingRoomNetworkService: RoomSharingNetworkServiceProtocol
    ) {
        self.entityType = entityType
        self.roomSharingLinkAccesskService = roomSharingLinkAccesskService
        self.folderSharingNetworkService = folderSharingNetworkService
        self.sharingRoomNetworkService = sharingRoomNetworkService
    }
}

// MARK: - SharingInfoLinkAccessServiceImp

extension SharingInfoLinkAccessServiceImp: SharingInfoLinkAccessService {
    func fetchLinksAndUsers() async throws -> ([SharingInfoLinkResponseModel], [RoomUsersResponseModel]) {
        switch entityType {
        case let .room(room):
            try await sharingRoomNetworkService.fetch(room: room)
        case .file:
            // TODO: Sharing info stub
            ([], [])
        case let .folder(folder):
            try await folderSharingNetworkService.fetch(folder: folder)
        }
    }

    func createGeneralLink() async throws -> SharingInfoLinkModel {
        switch entityType {
        case let .room(room):
            try await roomSharingLinkAccesskService.createGeneralLink(room: room)
        case .file:
            // TODO: Sharing info stub
            throw NetworkingError.invalidData
        case .folder:
            // TODO: Sharing info stub
            throw NetworkingError.invalidData
        }
    }

    func createLink(
        title: String,
        linkType: ASCShareLinkType
    ) async throws -> SharingInfoLinkModel {
        switch entityType {
        case let .room(room):
            try await roomSharingLinkAccesskService.createLink(
                title: title,
                linkType: linkType,
                room: room
            )
        case .file:
            // TODO: Sharing info stub
            throw NetworkingError.invalidData
        case .folder:
            // TODO: Sharing info stub
            throw NetworkingError.invalidData
        }
    }

    func removeLink(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?
    ) async throws {
        switch entityType {
        case let .room(room):
            try await roomSharingLinkAccesskService.removeLink(
                id: id,
                title: title,
                linkType: linkType,
                password: password,
                room: room
            )
        case .file:
            // TODO: Sharing info stub
            throw NetworkingError.invalidData
        case .folder:
            // TODO: Sharing info stub
            throw NetworkingError.invalidData
        }
    }
}
