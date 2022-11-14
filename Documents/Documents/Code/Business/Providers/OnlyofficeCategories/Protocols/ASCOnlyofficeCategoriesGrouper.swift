//
//  ASCOnlyofficeCategoriesGrouper.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 8.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCOnlyofficeCategoriesGroup {
    typealias CategoryGroup = [ASCOnlyofficeCategory]
    typealias TitledGroup = (title: String, categories: CategoryGroup)

    case notGroupd([ASCOnlyofficeCategory])
    case titledGroups([TitledGroup])
}

protocol ASCOnlyofficeCategoriesGrouper {
    func group(categories: [ASCOnlyofficeCategory]) -> ASCOnlyofficeCategoriesGroup
}
