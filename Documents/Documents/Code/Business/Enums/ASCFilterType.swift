//
//  ASCFilterType.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCFilterType: Int {
    case none               = 0
    case filesOnly          = 1
    case foldersOnly        = 2
    case documentsOnly      = 3
    case presentationsOnly  = 4
    case spreadsheetsOnly   = 5
    case imagesOnly         = 7
    case byUser             = 8
    case byDepartment       = 9
}
