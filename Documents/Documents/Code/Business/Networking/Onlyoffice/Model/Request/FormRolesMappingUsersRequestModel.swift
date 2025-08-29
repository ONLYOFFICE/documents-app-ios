//
//  FormRolesMappingUsersRequestModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 19/08/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

struct FormRolesMappingUsersRequestModel: Encodable {
    let formId: Int
    let roles: [Role]
}

extension FormRolesMappingUsersRequestModel {
    struct Role: Encodable {
        let userId: String
        let roleName: String
        let roleColor: String
        let roomId: Int
    }
}
