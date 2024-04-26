//
//  DocumentServerVersionResponse.swift
//  Documents
//
//  Created by Alexander Yuzhin on 26.04.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct DocumentServerVersionResponse: Codable {
    var docServiceUrlApi: String?
    var version: String?
}
