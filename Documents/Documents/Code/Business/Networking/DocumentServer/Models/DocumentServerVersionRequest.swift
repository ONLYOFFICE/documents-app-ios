//
//  DocumentServerVersionRequest.swift
//  Documents
//
//  Created by Alexander Yuzhin on 26.04.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct DocumentServerVersionRequest: Codable {
    enum Version: String, Codable {
        case `true`
    }

    var version: Version = .true

    init(version: Version = .true) {
        self.version = version
    }
}
