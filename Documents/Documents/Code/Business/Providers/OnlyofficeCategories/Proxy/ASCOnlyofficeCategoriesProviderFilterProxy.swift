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
    
    func loadCategories(completion: @escaping (Result<[ASCOnlyofficeCategory], Error>) -> Void) {
        categoriesProvider.loadCategories { result in
            switch result {
            case .success(let categories):
                completion(.success(categories.filter(self.filter)))
            case .failure(_):
                completion(result)
            }
        }
    }
}
