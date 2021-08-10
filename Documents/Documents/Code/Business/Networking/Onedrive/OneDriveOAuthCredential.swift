//
//  OneDriveOAuthCredential.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire

struct OneDriveOAuthCredential: AuthenticationCredential {
    let accessToken: String
    let refreshToken: String
    let expiration: Date

    var requiresRefresh: Bool {
        return expiration < Date()
    }
}
