//
//  ASCOnlyofficeCategoriesDefaultGrouper.swift
//  Documents
//
//  Created by Pavel Chernyshev on 8.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeCategoriesDefaultGrouper: ASCOnlyofficeCategoriesGrouper {
    func group(categories: [ASCOnlyofficeCategory]) -> ASCOnlyofficeCategoriesGroup {
        .notGroupd(categories)
    }
}
