//
//  NextcloudEndpoints.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 30.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire

class NextcloudAPI {

    struct Path {
        static public let storageStats = "index.php/apps/files/ajax/getstoragestats.php"
    }

    struct Endpoints {
        static let currentAccount: Endpoint<NextcloudDataResult<NextcloudStorageStats>> = Endpoint<NextcloudDataResult<NextcloudStorageStats>>.make(Path.storageStats, .get, nil, URLEncoding.default)
    }

}
