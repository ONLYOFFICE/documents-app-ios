//
//  ASCTemplateAccessModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 06.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct ASCTemplateAccessModel: Codable {
    var access: Int?
    var sharedTo: ASCUser?
    var isLocked: Bool?
    var isOwner: Bool
    var canEditAccess: Bool
    var subjectType: Int
}
