//
//  RoomLinkRequestModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

struct RoomLinkRequestModel: Codable {
    var linkId: String?
    var title: String
    var access: Int
    var expirationDate: String
    var linkType: Int
    var denyDownload: Bool
}
