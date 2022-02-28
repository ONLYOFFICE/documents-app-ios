//
//  ASCFolderType.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCFolderType: Int {
    case unknown = 0

    case onlyofficeCommon = 1
    case onlyofficeBunch = 2
    case onlyofficeTrash = 3
    case onlyofficeUser = 5
    case onlyofficeShare = 6
    case onlyofficeProjects = 8
    case onlyofficeFavorites = 10
    case onlyofficeRecent = 11

    case deviceDocuments = 50
    case deviceTrash = 51

    case nextcloudAll = 101
    case owncloudAll = 102
    case yandexAll = 103
    case webdavAll = 104
    case dropboxAll = 105
    case googledriveAll = 106
    case icloudAll = 107
    case onedriveAll = 108
    case kdriveAll = 109
}
