//
//  RoomTagsListRequestModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 03.02.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct RoomTagsListRequestModel: Codable {
    var startIndex: Int = 0
    var count: Int = 100
}
