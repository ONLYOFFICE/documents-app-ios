//
//  ASCOnlyofficeAppBasedCategoriesProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeAppBasedCategoriesProvider: ASCOnlyofficeCategoriesProviderProtocol {
    var categoriesCurrentlyLoading: Bool = false
    
    func loadCategories(completion: @escaping ([ASCOnlyofficeCategory]) -> Void) {
        if let onlyoffice = ASCFileManager.onlyofficeProvider, let user = onlyoffice.user {
            
            categoriesCurrentlyLoading = true
            
            var categories: [ASCOnlyofficeCategory] = []

            let isPersonal = onlyoffice.api.baseUrl?.contains(ASCConstants.Urls.portalPersonal) ?? false
            let allowMy = !user.isVisitor
            let allowShare = !isPersonal
            let allowCommon = !isPersonal
            let allowProjects = !(user.isVisitor || isPersonal)

            // My Documents
            if allowMy {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeUser)
                    $0.image = Asset.Images.categoryMy.image
                    $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeUser)
                    return $0
                }(ASCOnlyofficeCategory()))
            }

            // Shared with Me Category
            if allowShare {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeShare)
                    $0.image = Asset.Images.categoryShare.image
                    $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeShare)
                    return $0
                    }(ASCOnlyofficeCategory()))
            }

            // Common Documents Category
            if allowCommon {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeCommon)
                    $0.image = Asset.Images.categoryCommon.image
                    $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeCommon)
                    return $0
                    }(ASCOnlyofficeCategory()))
            }

            // Project Documents Category
            if allowProjects {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeProjects)
                    $0.image = Asset.Images.categoryProjects.image
                    $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeProjects)
                    return $0
                    }(ASCOnlyofficeCategory()))
            }

            // Trash Category
            categories.append({
                $0.title = ASCOnlyofficeCategory.title(of: .onlyofficeTrash)
                $0.image = Asset.Images.categoryTrash.image
                $0.folder = ASCOnlyofficeCategory.folder(of: .onlyofficeTrash)
                return $0
                }(ASCOnlyofficeCategory()))
            
            categoriesCurrentlyLoading = false
            completion(categories)
        } else {
            completion([])
        }
    }
}
