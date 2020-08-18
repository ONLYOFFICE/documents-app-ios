//
//  ASCFolderProviderType.swift
//  Documents
//
//  Created by Alexander Yuzhin on 02/07/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ASCFolderProviderType: String, CaseIterable {
    case boxNet         = "Box"
    case dropBox        = "DropboxV2"
    case google         = "Google"
    case googleDrive    = "GoogleDrive"
    case sharePoint     = "SharePoint"
    case skyDrive       = "SkyDrive"
    case oneDrive       = "OneDrive"
    case webDav         = "WebDav"
    case yandex         = "Yandex"
    case nextCloud      = "NextCloud"
    case ownCloud       = "ownCloud"
}
