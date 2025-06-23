//
//  CreateRoomFromTemplateModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 06.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import UIKit

struct CreateRoomFromTemplateModel {
    let templateId: Int
    let roomType: ASCRoomType
    let title: String
    let color: String
    let denyDownload: Bool
    let indexing: Bool
    let logo: UIImage?
    let copyLogo: Bool
}
