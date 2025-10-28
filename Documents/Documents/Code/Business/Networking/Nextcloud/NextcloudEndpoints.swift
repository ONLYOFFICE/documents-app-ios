//
//  NextcloudEndpoints.swift
//  Documents
//
//  Created by Alexander Yuzhin on 30.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

enum NextcloudAPI {
    enum Path {
        static let currentUser = "ocs/v2.php/cloud/user"
    }

    enum Endpoints {
        static let currentUser: Endpoint<NextcloudOCSResponse<NextcloudUserData>> =
            Endpoint<NextcloudOCSResponse<NextcloudUserData>>.make(Path.currentUser, .get, URLEncoding.default)
    }
}
