//
//  AddSharedLinkRequestModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 11.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct AddSharedLinkRequestModel: Codable {
    var access: Int
    var primary: Bool
    var isInternal: Bool

    enum CodingKeys: String, CodingKey {
        case isInternal = "internal"
        case access, primary
    }
}
