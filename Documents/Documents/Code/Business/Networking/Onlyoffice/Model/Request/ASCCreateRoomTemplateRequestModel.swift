//
//  ASCCreateRoomTemplateRequestModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 25.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation

struct ASCCreateRoomTemplateRequestModel: Codable {
    let title: String?
    let roomId: Int?
    let tags: [String]?
    let `public`: Bool?
    let copylogo: Bool?
    let color: String?
}
