//
//  LogoUploadResult.swift
//  Documents
//
//  Created by Pavel Chernyshev on 13.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

struct LogoUploadResult: Codable {
    var success: Bool
    var tmpFileUrl: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case tmpFileUrl = "data"
    }
}
