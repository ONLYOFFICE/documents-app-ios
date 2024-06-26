//
//  EditSharedLinkRequestModel.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 06.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct EditSharedLinkRequestModel: Codable {
    var linkId: String
    var access: Int
    var primary: Bool
    var isInternal: Bool
    var expirationDate: String?

    enum CodingKeys: String, CodingKey {
        case isInternal = "internal"
        case linkId, access, primary, expirationDate
    }
}
