//
//  ASCEntityExistenceCheckerByAttributes.swift
//  Documents
//
//  Created by Pavel Checker on 04.12.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import FilesProvider

class ASCEntityExistenceCheckerByAttributes: ASCEntityExistenceChecker {
    
    let provider: HTTPFileProvider
    
    init(provider: HTTPFileProvider) {
        self.provider = provider
    }
    
    func isExist(entityFullName name: String, completion: @escaping (Bool) -> Void) {
        provider.attributesOfItem(path: name) { entity, error in
            if entity != nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
