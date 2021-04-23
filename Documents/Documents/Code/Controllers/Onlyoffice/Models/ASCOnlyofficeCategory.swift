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
        self.title = folder.title
        self.image = Self.image(of: folder.rootFolderType)
        self.folder = folder
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
