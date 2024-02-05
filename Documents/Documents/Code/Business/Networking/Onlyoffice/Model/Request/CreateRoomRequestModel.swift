//
//  CreateRoomRequestModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 14.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

struct CreateRoomRequestModel: Codable {
    var roomType: Int
    var title: String
}
