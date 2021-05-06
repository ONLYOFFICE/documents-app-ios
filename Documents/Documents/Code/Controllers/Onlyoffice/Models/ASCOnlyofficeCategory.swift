//
//  ASCOnlyofficeCategory.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCOnlyofficeCategory: ASCCategory {
    
    var sortWeight = 500
    
    convenience init(folder: ASCFolder) {
        self.init()
        self.folder = folder
        self.title = folder.title.isEmpty
            ? Self.title(of: folder.rootFolderType)
            : folder.title
        self.image = Self.image(of: folder.rootFolderType)
        self.folder?.id = Self.id(of: folder.rootFolderType)
        self.sortWeight = Self.sortWeight(of: folder.rootFolderType)
    }
    
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
    
    static func image(of type: ASCFolderType) -> UIImage? {
        switch type {
        case .onlyofficeCommon:
            return Asset.Images.categoryCommon.image
        case .onlyofficeTrash:
            return Asset.Images.categoryTrash.image
        case .onlyofficeUser:
            return Asset.Images.categoryMy.image
        case .onlyofficeShare:
            return Asset.Images.categoryShare.image
        case .onlyofficeProjects:
            return Asset.Images.categoryProjects.image
        case .onlyofficeFavorites:
            return Asset.Images.categoryFavorites.image
        case .onlyofficeRecent:
            return Asset.Images.categoryRecent.image
        default:
            return nil
        }
    }
    
    static func sortWeight(of type: ASCFolderType) -> Int {
        switch type {
        case .onlyofficeUser:
            return 10
        case .onlyofficeShare:
            return 20
        case .onlyofficeFavorites:
            return 30
        case .onlyofficeRecent:
            return 40
        case .onlyofficeCommon:
            return 60
        case .onlyofficeProjects:
            return 70
        case .onlyofficeTrash:
            return 80
        default:
            return 500
        }
    }
    
    static func id(of type: ASCFolderType) -> String {
        switch type {
        case .onlyofficeUser:
            return ASCOnlyOfficeApi.apiFolderMy
        case .onlyofficeShare:
            return ASCOnlyOfficeApi.apiFolderShare
        case .onlyofficeFavorites:
            return ASCOnlyOfficeApi.apiFolderFavorites
        case .onlyofficeRecent:
            return ASCOnlyOfficeApi.apiFolderRecent
        case .onlyofficeCommon:
            return ASCOnlyOfficeApi.apiFolderCommon
        case .onlyofficeProjects:
            return ASCOnlyOfficeApi.apiFolderProjects
        case .onlyofficeTrash:
            return ASCOnlyOfficeApi.apiFolderTrash
        default:
            return ""
        }
    }
    
    static func allowToMoveAndCopy(of type: ASCFolderType) -> Bool {
        switch type {
        case .onlyofficeUser:
            return true
        case .onlyofficeShare:
            return true
        case .onlyofficeCommon:
            return true
        case .onlyofficeProjects:
            return true
        default:
            return false
        }
    }
    
    static func allowToMoveAndCopy(category: ASCOnlyofficeCategory) -> Bool {
        allowToMoveAndCopy(of: category.folder?.rootFolderType ?? . unknown)
    }

    static func folder(of type: ASCFolderType) -> ASCFolder? {
        switch type {
        case .onlyofficeUser,
             .onlyofficeShare,
             .onlyofficeCommon,
             .onlyofficeProjects,
             .onlyofficeTrash:
            return {
                $0.title = Self.title(of: type)
                $0.rootFolderType = type
                $0.id = Self.id(of: type)
                return $0
            }(ASCFolder())
        case .onlyofficeBunch:
            return {
                $0.title = Self.title(of: .onlyofficeProjects)
                $0.rootFolderType = .onlyofficeProjects
                $0.id = Self.id(of: .onlyofficeProjects)
                return $0
            }(ASCFolder())
        default:
            return nil
        }
    }
}
