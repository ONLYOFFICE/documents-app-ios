//
//  DropboxEndpoints.swift
//  Documents
//
//  Created by Alexander Yuzhin on 30.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire

class DropboxAPI {

    struct Path {
        static public let currentAccount = "users/get_current_account"
        static public let temporaryLink = "files/get_temporary_link"
    }

    struct Endpoints {
        static let currentAccount: Endpoint<DropboxAccount> = Endpoint<DropboxAccount>.make(Path.currentAccount, .post)
    }

}
