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
    var protalTypeDefinder: ASCPortalTypeDefinderProtocol = ASCPortalTypeDefinderByCurrentConnection()
    func loadCategories(completion: @escaping (Result<[ASCOnlyofficeCategory], Error>) -> Void) {
        if let onlyoffice = ASCFileManager.onlyofficeProvider, let user = onlyoffice.user {
            categoriesCurrentlyLoading = true

            var categories: [ASCOnlyofficeCategory] = []

            let isPersonal = protalTypeDefinder.definePortalType() == .personal
            let allowMy = !user.isVisitor
            let allowShare = true
            let allowCommon = !isPersonal
            let allowProjects = !(user.isVisitor || isPersonal)

            // My Documents
            if allowMy {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .user)
                    $0.image = Asset.Images.categoryMy.image
                    $0.folder = ASCOnlyofficeCategory.folder(of: .user)
                    return $0
                }(ASCOnlyofficeCategory()))
            }

            // Shared with Me Category
            if allowShare {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .share)
                    $0.image = Asset.Images.categoryShare.image
                    $0.folder = ASCOnlyofficeCategory.folder(of: .share)
                    return $0
                }(ASCOnlyofficeCategory()))
            }

            // Common Documents Category
            if allowCommon {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .common)
                    $0.image = Asset.Images.categoryCommon.image
                    $0.folder = ASCOnlyofficeCategory.folder(of: .common)
                    return $0
                }(ASCOnlyofficeCategory()))
            }

            // Project Documents Category
            if allowProjects {
                categories.append({
                    $0.title = ASCOnlyofficeCategory.title(of: .projects)
                    $0.image = Asset.Images.categoryProjects.image
                    $0.folder = ASCOnlyofficeCategory.folder(of: .projects)
                    return $0
                }(ASCOnlyofficeCategory()))
            }

            // Trash Category
            categories.append({
                $0.title = ASCOnlyofficeCategory.title(of: .trash)
                $0.image = Asset.Images.categoryTrash.image
                $0.folder = ASCOnlyofficeCategory.folder(of: .trash)
                return $0
            }(ASCOnlyofficeCategory()))

            categoriesCurrentlyLoading = false
            completion(.success(categories))
        } else {
            categoriesCurrentlyLoading = false
            completion(.success([]))
        }
    }
}
