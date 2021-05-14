//
//  ASCOnlyofficeAPICategoriesProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 22.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeAPICategoriesProvider: ASCOnlyofficeCategoriesProviderProtocol {
    var categoriesCurrentlyLoading: Bool = false
    
    func loadCategories(completion: @escaping ([ASCOnlyofficeCategory]) -> Void) {
        var categories: [ASCOnlyofficeCategory] = []
        guard !categoriesCurrentlyLoading else {
            completion(categories)
            return
        }
        
        categoriesCurrentlyLoading = true
        DispatchQueue.global(qos: .userInteractive).async {
            let request = "\(ASCOnlyOfficeApi.apiFilesPath)\(ASCOnlyOfficeApi.apiFolderRoot)"
            
            ASCOnlyOfficeApi.get(request) { [self] (results, error, response) in
                if let results = results as? [[String: Any]] {
                    for item in results {
                        if let categoryInfo = item["current"] as? [String: Any],
                           let folder = ASCFolder(JSON: categoryInfo) {
                            let category = ASCOnlyofficeCategory(folder: folder)
                            categories.append(category)
                        }
                    }
                    categories.sort { $0.sortWeight < $1.sortWeight }
                }
                DispatchQueue.main.async {
                    completion(categories)
                }
                categoriesCurrentlyLoading = false
            }
        }
    }
    
    
}
