//
//  DropboxEndpoints.swift
//  Documents
//
//  Created by Alexander Yuzhin on 30.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

class DropboxAPI {
    enum Path {
        public static let currentAccount = "users/get_current_account"
        public static let temporaryLink = "files/get_temporary_link"
    }

    enum Endpoints {
        static let currentAccount: Endpoint<DropboxAccount> = Endpoint<DropboxAccount>.make(Path.currentAccount, .post)
    }
}
