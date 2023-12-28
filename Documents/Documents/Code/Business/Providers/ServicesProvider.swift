//
//  ServicesProvider.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 28/12/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

final class ServicesProvider {
    static let shared = ServicesProvider()

    private init() {}

    private(set) lazy var roomCreateService: CreatingRoomService = NetworkCreatingRoomServiceImp()

    private(set) lazy var roomUsersAccessNetworkService: RoomUsersAccessNetworkService = RoomUsersAccessNetworkServiceImp()

    private(set) lazy var roomSharingNetworkService: RoomSharingNetworkServiceProtocol = RoomSharingNetworkService()
}
