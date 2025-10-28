//
//  DropboxEndpoints.swift
//  Documents
//
//  Created by Alexander Yuzhin on 30.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

enum DropboxAPI {
    enum URL {
        static let api = "https://api.dropboxapi.com"
    }

    enum Path {
        static let currentAccount = "users/get_current_account"
        static let temporaryLink = "files/get_temporary_link"
        static let token = "oauth2/token"
    }

    enum Endpoints {
        static let currentAccount: Endpoint<DropboxAccount> = Endpoint<DropboxAccount>.make(Path.currentAccount, .post)
    }
}
