//
//  CreateRoomRequestModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 14.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

struct CreateRoomRequestModel: Codable {
    var roomType: Int
    var title: String
    var createAsNewFolder: Bool
    var indexing: Bool
    var denyDownload: Bool
    var lifetime: FileLifetime?
    var watermark: Watermark?

    struct FileLifetime: Codable {
        var fileAge: Int
        var deletePermanently: Bool
        var periodType: PeriodType

        enum CodingKeys: String, CodingKey {
            case fileAge = "value"
            case deletePermanently
            case periodType = "period"
        }

        enum PeriodType: Int, Codable {
            case days = 0
            case months
            case years
        }
    }
    
    struct Watermark: Codable {
        var rotate: Int
        var text: String
        /// Watermark elements
        var additions: Int
    }
}
