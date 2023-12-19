//
//  ASCLink.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

struct ASCLink: Codable {
    let id: String
    let title: String
    let access: Int
    let linkType: Int
    let password: String
    let denyDownload: Bool

    enum CodingKeys: String, CodingKey {
        case id = "linkId"
        case title, access, linkType, password, denyDownload
    }
}
