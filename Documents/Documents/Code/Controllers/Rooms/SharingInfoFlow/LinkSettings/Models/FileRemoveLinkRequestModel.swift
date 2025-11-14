//
//  FileRemoveLinkRequestModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 14.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct RemoveLinkRequestModel: Codable {
    var linkId: String
    var access: Int
    var primary: Bool
    var `internal`: Bool
    var expirationDate: String?
    var denyDownload: Bool
    var title: String
    var password: String?
}
