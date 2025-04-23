//
//  ASCDeleteVersionRequestModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 23.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct ASCDeleteVersionRequestModel: Codable {
    let fileId: Int?
    let versions: [Int]?
}
