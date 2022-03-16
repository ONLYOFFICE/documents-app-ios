//
//  OnedriveEndpoints.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class OnedriveAPI {
    enum Path {
        public static let me = "me"
    }

    enum Endpoints {
        static let me: Endpoint<ASCUser> = Endpoint<ASCUser>.make(Path.me)
    }
}
