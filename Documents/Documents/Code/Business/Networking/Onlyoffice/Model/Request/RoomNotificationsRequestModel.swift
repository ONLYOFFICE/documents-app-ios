//
//  RoomNotificationsRequestModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 01.04.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct RoomNotificationsRequestModel: Codable {
    let roomsID: Int
    let mute: Bool

    enum CodingKeys: String, CodingKey {
        case roomsID = "RoomsId"
        case mute = "Mute"
    }
}
