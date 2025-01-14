//
//  FilesOrderRequesModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 13.01.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Alamofire

struct FilesOrderRequestModel: Codable {
    var items: [FilesOrderItemRequestModel]
}

struct FilesOrderItemRequestModel: Codable {
    var order: String
    var entryId: Int
    var entryType: Int
}

extension Array where Element == ASCEntity {
    var filesOrderRequestModel: FilesOrderRequestModel {
        let items = map {
            FilesOrderItemRequestModel(
                order: $0.orderIndex ?? "",
                entryId: Int($0.id) ?? 0,
                entryType: $0 is ASCFolder ? 1 : 2
            )
        }
        return FilesOrderRequestModel(items: items)
    }
}
