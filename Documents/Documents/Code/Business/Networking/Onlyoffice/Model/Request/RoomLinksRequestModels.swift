//
//  RoomLinksRequestModels.swift
//  Documents
//
//  Created by Lolita Chernysheva on 22.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

struct RoomLinksRequestModel: Codable {
    var type: Int
}

struct RoomLinkRequestModel: Codable {
    var linkId: String?
    var title: String
    var access: Int
    var expirationDate: String?
    var linkType: Int
    var denyDownload: Bool
    var password: String?
}

struct RoomRemoveLinkRequestModel: Codable {
    var linkId: String
    var title: String
    var access: Int
    var linkType: Int
    var password: String?
}

struct RoomRevokeLinkRequestModel: Codable {
    var linkId: String
    var title: String
    var access: Int
    var linkType: Int
    var password: String?
    var denyDownload: Bool
}
