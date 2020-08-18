//
//  ASCOnlyofficeCategory.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCOnlyofficeCategory: ASCCategory {
    static func title(of type: ASCFolderType) -> String {
        switch type {
        case .onlyofficeUser:
            return NSLocalizedString("My Documents", comment: "Category title")
        case .onlyofficeShare:
            return NSLocalizedString("Shared with Me", comment: "Category title")
        case .onlyofficeCommon:
            return NSLocalizedString("Common Documents", comment: "Category title")
        case .onlyofficeBunch, .onlyofficeProjects:
            return NSLocalizedString("Project Documents", comment: "Category title")
        case .onlyofficeTrash:
            return NSLocalizedString("Trash", comment: "Category title")
        default:
            return ""
        }
    }

    static func folder(of type: ASCFolderType) -> ASCFolder? {
        switch type {
        case .onlyofficeUser:
            return {
                $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeUser)
                $0.rootFolderType = .onlyofficeUser
                $0.id = ASCOnlyOfficeApi.apiFolderMy
                return $0
            }(ASCFolder())
        case .onlyofficeShare:
            return {
                $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeShare)
                $0.rootFolderType = .onlyofficeShare
                $0.id = ASCOnlyOfficeApi.apiFolderShare
                return $0
            }(ASCFolder())
        case .onlyofficeCommon:
            return {
                $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeCommon)
                $0.rootFolderType = .onlyofficeCommon
                $0.id = ASCOnlyOfficeApi.apiFolderCommon
                return $0
            }(ASCFolder())
        case .onlyofficeBunch, .onlyofficeProjects:
            return {
                $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeProjects)
                $0.rootFolderType = .onlyofficeProjects
                $0.id = ASCOnlyOfficeApi.apiFolderProjects
                return $0
            }(ASCFolder())
        case .onlyofficeTrash:
            return {
                $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeTrash)
                $0.rootFolderType = .onlyofficeTrash
                $0.id = ASCOnlyOfficeApi.apiFolderTrash
                return $0
            }(ASCFolder())
        default:
            return nil
        }
    }
}
