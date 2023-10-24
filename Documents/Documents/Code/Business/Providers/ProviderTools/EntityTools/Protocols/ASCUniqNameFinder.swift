//
//  ASCUniqNameFinder.swift
//  Documents
//
//  Created by Pavel Chernyshev on 04.12.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCUniqNameFinder {
    typealias UniqName = String
    func find(bySuggestedName suggestedName: String, atPath path: String, completion: @escaping (UniqName) -> Void)
}
