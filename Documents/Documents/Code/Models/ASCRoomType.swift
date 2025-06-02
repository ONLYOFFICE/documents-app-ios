//
//  ASCRoomType.swift
//  Documents
//
//  Created by Pavel Chernyshev on 13.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

enum ASCRoomType: Int {
    case fillingForm = 1
    case colobaration = 2
    case review = 3
    case viewOnly = 4
    case custom = 5
    case `public` = 6
    case virtualData = 8

    var image: UIImage {
        switch self {
        case .fillingForm:
            return Asset.Images.listRoomFillingFormsBlue.image
        case .colobaration:
            return Asset.Images.listRoomCollaboration.image
        case .review:
            return Asset.Images.listRoomReview.image
        case .viewOnly:
            return Asset.Images.listRoomViewOnly.image
        case .custom:
            return Asset.Images.listRoomCustom.image
        case .public:
            return Asset.Images.listRoomPublicPlanet.image
        case .virtualData:
            return Asset.Images.listRoomVdr.image
        default:
            return Asset.Images.listRoomDefault.image
        }
    }
}

extension ASCRoomType {
    var description: String? {
        switch self {
        case .custom:
            return CreatingRoomType.custom.name
        case .public:
            return CreatingRoomType.publicRoom.name
        case .colobaration:
            return CreatingRoomType.collaboration.name
        case .fillingForm:
            return CreatingRoomType.formFilling.name
        case .virtualData:
            return CreatingRoomType.virtualData.name
        default:
            return nil
        }
    }
}
