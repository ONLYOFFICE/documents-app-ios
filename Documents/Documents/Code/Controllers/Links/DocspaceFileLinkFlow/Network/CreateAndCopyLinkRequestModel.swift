//
//  CreateAndCopyLinkRequestModel.swift
//  Documents
//
//  Created by Victor Tihovodov on 2/6/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct CreateAndCopyLinkRequestModel: Codable {
    var access: Int
    var expirationDate: String?
    var isInternal: Bool

    enum CodingKeys: String, CodingKey {
        case isInternal = "internal"
        case access, expirationDate
    }
}
