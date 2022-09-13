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

    var image: UIImage {
        switch self {
        case .fillingForm:
            return Asset.Images.roomFillingForms.image
        case .colobaration:
            return Asset.Images.roomCollaboration.image
        case .review:
            return Asset.Images.roomReview.image
        case .viewOnly:
            return Asset.Images.roomViewOnly.image
        case .custom:
            return Asset.Images.roomCustom.image
        }
    }
}
