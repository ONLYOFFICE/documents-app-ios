//
//  ASCFolderType.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCFolderType: Int {
    case unknown                = 0

    case onlyofficeCommon       = 1
    case onlyofficeBunch        = 2
    case onlyofficeTrash        = 3
    case onlyofficeUser         = 5
    case onlyofficeShare        = 6
    case onlyofficeProjects     = 8

    case deviceDocuments        = 9
    case deviceTrash            = 10

    case nextcloudAll           = 101
    case owncloudAll            = 102
    case yandexAll              = 103
    case webdavAll              = 104
    case dropboxAll             = 105
    case googledriveAll         = 106
}
