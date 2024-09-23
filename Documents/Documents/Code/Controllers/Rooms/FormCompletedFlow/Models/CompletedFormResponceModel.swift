//
//  CompletedFormResponceModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 18.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

struct CompletedFormResponceModel: Codable {
    let formNumber: Int
    let roomId: Int
    let manager: FormManager?
}

struct FormManager: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let displayName: String?
    let avatar: String?
}
