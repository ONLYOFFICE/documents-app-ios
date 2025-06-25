//
//  ASCDeleteRoomTemplateRequestModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 28.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation

struct ASCDeleteRoomTemplateRequestModel: Codable {
    let folderIds: [String]
    let fileIds: [String]
}
