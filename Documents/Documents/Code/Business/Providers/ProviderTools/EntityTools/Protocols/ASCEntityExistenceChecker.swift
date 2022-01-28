//
//  EntityExistChecker.swift
//  Documents
//
//  Created by Pavel Chernyshev on 04.12.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCEntityExistenceChecker {
    func isExist(entityFullName name: String, completion: @escaping (Bool) -> Void)
}
