//
//  SharePasswordResponseModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 24.01.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct SharePasswordResponseModel: Codable {
    var status: Int?
    var id: String
    var title: String
    var tenantId: Int?
    var shared: Bool = false
    var linkId: String?
    var isAuthenticated: Bool = false
}
