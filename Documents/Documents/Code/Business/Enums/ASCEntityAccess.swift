//
//  ASCEntityAccess.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCEntityAccess: Int {
    case none               = 0
    case readWrite          = 1
    case read               = 2
    case restrict           = 3
    case varies             = 4
    case review             = 5
    case comment            = 6
    case fillforms          = 7
}
