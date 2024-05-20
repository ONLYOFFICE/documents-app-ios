//
//  UserModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 16.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

enum UserList {}

extension UserList {
    struct User: Identifiable {
        let id: String
        let name: String
        let role: String
        let email: String
        let imageName: String

        var imageUrl: URL? {
            let urlStr = imageName
            if !urlStr.isEmpty,
               !urlStr.contains("/default_user_photo_size_"),
               let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed
            {
                return URL(string: portal + urlStr)
            }
            return nil
        }
    }
}
