//
//  ASCFileStatus.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCFileStatus: Int {
    case none               = 0x0
    case isEditing          = 0x1
    case isNew              = 0x2
    case isConverting       = 0x4
    case isOriginal         = 0x8
    case backup             = 0x10
}
