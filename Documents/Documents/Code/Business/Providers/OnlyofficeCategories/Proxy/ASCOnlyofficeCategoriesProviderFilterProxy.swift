//
//  ASCOnlyofficeCategoriesProviderFilterProxy.swift
//  Documents
//
//  Created by Pavel Chernyshev on 26.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeCategoriesProviderFilterProxy: ASCOnlyofficeCategoriesProviderProtocol {
    
    let categoriesProvider: ASCOnlyofficeCategoriesProviderProtocol
    let filter: (ASCOnlyofficeCategory) -> Bool
    
    var categoriesCurrentlyLoading: Bool {
        categoriesProvider.categoriesCurrentlyLoading
    }
    
    init(categoriesProvider: ASCOnlyofficeCategoriesProviderProtocol, filter: @escaping (ASCOnlyofficeCategory) -> Bool) {
        self.categoriesProvider = categoriesProvider
        self.filter = filter
    }
    
    func loadCategories(completion: @escaping ([ASCOnlyofficeCategory]) -> Void) {
        categoriesProvider.loadCategories { categories in
            completion(categories.filter(self.filter))
        }
    }
}
