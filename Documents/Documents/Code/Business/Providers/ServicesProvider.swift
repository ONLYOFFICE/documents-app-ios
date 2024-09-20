//
//  ServicesProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28/12/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

final class ServicesProvider {
    static let shared = ServicesProvider()

    private init() {}

    private(set) lazy var roomCreateService: ManagingRoomService = NetworkManagingRoomServiceImp()

    private(set) lazy var roomUsersAccessNetworkService: RoomUsersAccessNetworkService = RoomUsersAccessNetworkServiceImp()

    private(set) lazy var roomSharingNetworkService: RoomSharingNetworkServiceProtocol = RoomSharingNetworkService()

    private(set) lazy var roomSharingLinkAccesskService: RoomSharingLinkAccessService = RoomSharingLinkAccessNetworkService()

    private(set) lazy var copyFileInsideProviderService: CopyFileInsideProviderService = CopyFileInsideProviderServiceImp()
}
