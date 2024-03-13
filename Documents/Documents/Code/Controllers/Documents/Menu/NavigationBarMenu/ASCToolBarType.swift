//
//  ASCToolBarType.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 13.03.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct ASCToolBarType: OptionSet {
    let rawValue: Int

    static let createRoom = ASCToolBarType(rawValue: 1 << 0)
    static let move = ASCToolBarType(rawValue: 1 << 1)
    static let copy = ASCToolBarType(rawValue: 1 << 2)
    static let restore = ASCToolBarType(rawValue: 1 << 3)
    static let restoreRoom = ASCToolBarType(rawValue: 1 << 4)
    static let remove = ASCToolBarType(rawValue: 1 << 5)
    static let removeAll = ASCToolBarType(rawValue: 1 << 6)
    static let removeFromList = ASCToolBarType(rawValue: 1 << 7)
    static let removeAllRooms = ASCToolBarType(rawValue: 1 << 8)
    static let info = ASCToolBarType(rawValue: 1 << 9)
    static let pin = ASCToolBarType(rawValue: 1 << 10)
    static let archive = ASCToolBarType(rawValue: 1 << 11)
    static let unarchive = ASCToolBarType(rawValue: 1 << 12)
    static let neededUpdateToolBarOnSelection = ASCToolBarType(rawValue: 1 << 13)
    static let neededUpdateToolBarOnDeselection = ASCToolBarType(rawValue: 1 << 14)
}
