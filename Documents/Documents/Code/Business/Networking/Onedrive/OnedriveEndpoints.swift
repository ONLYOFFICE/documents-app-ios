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
        static public let me = "me"
    }

    struct Endpoints {
        static let me: Endpoint<ASCUser> = Endpoint<ASCUser>.make(Path.me)
    }

}
