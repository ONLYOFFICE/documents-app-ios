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
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Folders.roots) { [self] response, error in
                if let paths = response?.result {
                    categories = paths.compactMap { path in
                        if let current = path.current {
                            return ASCOnlyofficeCategory(folder: current)
                        }
                        return nil
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
