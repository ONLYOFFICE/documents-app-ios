//
//  OnedriveEndpoints.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class OnedriveAPI {

    struct Path {
        static public let currentAccount = "users"
        static public let temporaryLink = "drive"
        static public let me = "me"
    }

    struct Endpoints {
        static let me: Endpoint<ASCUser> = Endpoint<DropboxAccount>.make(Path.me)
    }

}
