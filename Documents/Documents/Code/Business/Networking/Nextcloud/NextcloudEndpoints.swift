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
        public static let storageStats = "index.php/apps/files/ajax/getstoragestats.php"
    }

    enum Endpoints {
        static let currentAccount: Endpoint<NextcloudDataResult<NextcloudStorageStats>> = Endpoint<NextcloudDataResult<NextcloudStorageStats>>.make(Path.storageStats, .get, URLEncoding.default)
    }
}
