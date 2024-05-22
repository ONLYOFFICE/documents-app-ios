//
//  ChangeRoomOwnerRequestModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 16.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct ChangeRoomOwnerRequestModel: Codable {
    var userId: String
    var folderIds: [String]
}
