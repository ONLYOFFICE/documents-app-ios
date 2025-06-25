//
//  ASCCreateRoomFromTemplateRequestModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct ASCCreateRoomFromTemplateRequestModel: Codable {
    let templateId: Int?
    let roomType: Int?
    let title: String?
    let color: String?
    var denyDownload: Bool? = false
    var indexing: Bool? = false
    var copyLogo: Bool? = false
}
