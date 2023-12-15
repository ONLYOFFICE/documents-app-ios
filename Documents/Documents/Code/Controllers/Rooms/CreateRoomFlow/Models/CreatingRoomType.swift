//
//  CreatingRoomType.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 30.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

enum CreatingRoomType: CaseIterable {
    case collaboration
    case publicRoom
    case custom

    var id: Int {
        switch self {
        case .collaboration:
            return ascRoomType.rawValue
        case .publicRoom:
            return ascRoomType.rawValue
        case .custom:
            return ascRoomType.rawValue
        }
    }

    var name: String {
        switch self {
        case .collaboration:
            return NSLocalizedString("Collaboration room", comment: "")
        case .publicRoom:
            return NSLocalizedString("Public room", comment: "")
        case .custom:
            return NSLocalizedString("Custom room", comment: "")
        }
    }

    var description: String {
        switch self {
        case .collaboration:
            return NSLocalizedString("Collaborate on one or multiple documents with your team", comment: "")
        case .publicRoom:
            return NSLocalizedString("Invite users via shared links to view documents without registration. You can also embed this room into any web interface.", comment: "")
        case .custom:
            return NSLocalizedString("Apply your own settings to use this room for any custom purpose", comment: "")
        }
    }

    var icon: UIImage {
        switch self {
        case .collaboration:
            return ascRoomType.image
        case .publicRoom:
            return ascRoomType.image
        case .custom:
            return ascRoomType.image
        }
    }

    var ascRoomType: ASCRoomType {
        switch self {
        case .collaboration:
            return .colobaration
        case .publicRoom:
            return .public
        case .custom:
            return .custom
        }
    }
}
