//
//  ASCFileProviderType.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCFileProviderType: String, CaseIterable {
    case unknown        = "ASCFileProviderTypeUnknown"
    case local          = "ASCFileProviderTypeLocal"
    case onlyoffice     = "ASCFileProviderTypeOnlyoffice"
    case webdav         = "ASCFileProviderTypeWebDAV"
    case nextcloud      = "ASCFileProviderTypeNextcloud"
    case owncloud       = "ASCFileProviderTypeOwncloud"
    case yandex         = "ASCFileProviderTypeYandex"
    case dropbox        = "ASCFileProviderTypeDropbox"
    case googledrive    = "ASCFileProviderTypeGoogleDrive"
}
