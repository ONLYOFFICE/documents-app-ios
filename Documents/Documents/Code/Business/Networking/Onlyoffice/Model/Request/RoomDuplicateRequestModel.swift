//
//  RoomDuplicateRequestModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 05.08.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct RoomDuplicateRequestModel: Codable {
    let folderIds: [String]
    let fileIds: [String]
}
