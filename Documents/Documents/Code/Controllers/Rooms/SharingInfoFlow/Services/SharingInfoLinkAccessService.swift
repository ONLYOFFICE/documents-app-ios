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
    
    private let entityType: EntityType
    
    // MARK: Dependencies
    
    private let roomSharingLinkAccesskService: RoomSharingLinkAccessService
    private let sharingRoomNetworkService: RoomSharingNetworkServiceProtocol
    
    // MARK: Init
    
    init(
        entityType: EntityType,
        roomSharingLinkAccesskService: RoomSharingLinkAccessService,
        sharingRoomNetworkService: RoomSharingNetworkServiceProtocol
    ) {
        self.entityType = entityType
        self.roomSharingLinkAccesskService = roomSharingLinkAccesskService
        self.sharingRoomNetworkService = sharingRoomNetworkService
    }
}

// MARK: - SharingInfoLinkAccessServiceImp

extension SharingInfoLinkAccessServiceImp: SharingInfoLinkAccessService {
    
    func fetchLinksAndUsers() async throws -> ([SharingInfoLinkResponseModel], [RoomUsersResponseModel]) {
        switch entityType {
        case .room(let room):
            try await sharingRoomNetworkService.fetch(room: room)
        }
    }
    
    func createGeneralLink() async throws -> SharingInfoLinkModel {
        switch entityType {
        case .room(let room):
            try await roomSharingLinkAccesskService.createGeneralLink(room: room)
        }
    }
    
    func createLink(
        title: String,
        linkType: ASCShareLinkType
    ) async throws -> SharingInfoLinkModel {
        switch entityType {
        case .room(let room):
            try await roomSharingLinkAccesskService.createLink(
                title: title,
                linkType: linkType,
                room: room
            )
        }
    }
    
    func removeLink(
        id: String,
        title: String,
        linkType: ASCShareLinkType,
        password: String?
    ) async throws {
        switch entityType {
        case .room(let room):
            try await roomSharingLinkAccesskService.removeLink(
                id: id,
                title: title,
                linkType: linkType,
                password: password,
                room: room
            )
        }
    }
}

// MARK: - EntityType

extension SharingInfoLinkAccessServiceImp {
    
    enum EntityType {
        case room(ASCRoom)
    }
}
