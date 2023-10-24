//
//  ASCOnlyofficeCategoriesChainContainer.swift
//  Documents
//
//  Created by Pavel Chernyshev on 30.12.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCOnlyofficeCategoriesChainContainer: AnyObject, ASCOnlyofficeCategoriesProviderProtocol {
    var next: ASCOnlyofficeCategoriesProviderProtocol? { get }
    var currentlyExecuting: ASCOnlyofficeCategoriesProviderProtocol { get set }
}

class ASCOnlyofficeCategoriesChainContainerFailureToNext: ASCOnlyofficeCategoriesChainContainer {
    private(set) var base: ASCOnlyofficeCategoriesProviderProtocol
    var next: ASCOnlyofficeCategoriesProviderProtocol?
    var currentlyExecuting: ASCOnlyofficeCategoriesProviderProtocol

    init(base: ASCOnlyofficeCategoriesProviderProtocol, next: ASCOnlyofficeCategoriesProviderProtocol? = nil) {
        self.base = base
        currentlyExecuting = base
        self.next = next
    }

    var categoriesCurrentlyLoading: Bool {
        currentlyExecuting.categoriesCurrentlyLoading
    }

    func loadCategories(completion: @escaping (Result<[ASCOnlyofficeCategory], Error>) -> Void) {
        base.loadCategories { [weak self] result in
            guard let self = self else {
                completion(result)
                return
            }

            guard let next = self.next else {
                completion(result)
                return
            }

            switch result {
            case .success:
                completion(result)
            case .failure:
                self.currentlyExecuting = next
                next.loadCategories { result in
                    completion(result)
                }
            }
        }
    }
}
