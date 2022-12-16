//
//  ASCOnlyofficeAPICategoriesProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeAPICategoriesProvider: ASCOnlyofficeCategoriesProviderProtocol {
    var categoriesCurrentlyLoading: Bool = false

    func loadCategories(completion: @escaping (Result<[ASCOnlyofficeCategory], Error>) -> Void) {
        var categories: [ASCOnlyofficeCategory] = []
        guard !categoriesCurrentlyLoading else {
            completion(.success(categories))
            return
        }

        categoriesCurrentlyLoading = true
        DispatchQueue.global(qos: .userInteractive).async {
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Folders.roots) { [self] response, error in

                guard error == nil else {
                    log.error(error!)
                    categoriesCurrentlyLoading = false
                    DispatchQueue.main.async {
                        completion(.failure(error!))
                    }
                    return
                }

                if let paths = response?.result {
                    categories = paths.compactMap { path in
                        if let current = path.current {
                            return ASCOnlyofficeCategory(folder: current)
                        }
                        return nil
                    }
                    categories.sort { $0.sortWeight < $1.sortWeight }
                }

                setAppPriorityTitle(categories: categories)

                DispatchQueue.main.async {
                    completion(.success(categories))
                }

                categoriesCurrentlyLoading = false
            }
        }
    }

    func setAppPriorityTitle(categories: [ASCCategory]) {
        categories.forEach { category in
            let appPriorityTitle: String = {
                guard let rootFolderType = category.folder?.rootFolderType else { return "" }
                return ASCOnlyofficeCategory.title(of: rootFolderType)
            }()
            if !appPriorityTitle.isEmpty {
                category.title = appPriorityTitle
            }
        }
    }
}
