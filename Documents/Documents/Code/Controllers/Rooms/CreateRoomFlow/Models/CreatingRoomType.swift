//
//  CreatingRoomType.swift
//  Documents
//
//  Created by Pavel Chernyshev on 30.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

enum CreatingRoomType: CaseIterable {
    case publicRoom
    case formFilling
    case collaboration
    case virtualData
    case custom

    var id: Int {
        ascRoomType.rawValue
    }

    var name: String {
        switch self {
        case .collaboration:
            return NSLocalizedString("Collaboration room", comment: "")
        case .publicRoom:
            return NSLocalizedString("Public room", comment: "")
        case .custom:
            return NSLocalizedString("Custom room", comment: "")
        case .formFilling:
            return NSLocalizedString("Form Filling Room", comment: "")
        case .virtualData:
            return NSLocalizedString("Virtual Data Room", comment: "")
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
        case .formFilling:
            return NSLocalizedString("Upload PDF forms into the room. Invite users to fill out a PDF form. Review completed forms and analyze data automatically collected in a spreadsheet.", comment: "")
        case .virtualData:
            return NSLocalizedString("Use VDR for advanced file security and transparency. Set watermarks, automatically index and track all content, restrict downloading and copying.", comment: "")
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
        case .formFilling:
            return ascRoomType.image
        case .virtualData:
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
        case .formFilling:
            return .fillingForm
        case .virtualData:
            return .virtualData
        }
    }
}
