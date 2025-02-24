//
//  OnlyofficeFileOperation.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class OnlyofficeFileOperation: Mappable {
    var id: String?
    var operation: Int?
    var progress: Int?
    var error: String?
    var processed: String?
    var finished: Bool = false
    var url: String?
    var files: [ASCFile] = []
    var folders: [ASCFolder] = []

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        id <- map["id"]
        operation <- map["operation"]
        progress <- map["progress"]
        error <- map["error"]
        processed <- map["processed"]
        finished <- map["finished"]
        url <- map["url"]
        files <- map["files"]
        folders <- map["folders"]
    }
}

enum OnlyofficeFileOperationError: LocalizedError {
    case serverError(String)

    var localizedDescription: String? {
        switch self {
        case let .serverError(error):
            return error
        }
    }

    var errorDescription: String? {
        return localizedDescription
    }
}
