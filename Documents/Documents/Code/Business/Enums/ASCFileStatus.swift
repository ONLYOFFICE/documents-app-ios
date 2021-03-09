//
//  ASCFileStatus.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Foundation

struct ASCFileStatus: OptionSet {
    let rawValue: Int
    
    static let none               = ASCFileStatus([])
    static let isEditing          = ASCFileStatus(rawValue: 0x1)
    static let isNew              = ASCFileStatus(rawValue: 0x2)
    static let isConverting       = ASCFileStatus(rawValue: 0x4)
    static let isOriginal         = ASCFileStatus(rawValue: 0x8)
    static let isEditingAlone     = ASCFileStatus(rawValue: 0x10)
    static let isFavorite         = ASCFileStatus(rawValue: 0x20)
    static let isTemplate         = ASCFileStatus(rawValue: 0x40)
}
