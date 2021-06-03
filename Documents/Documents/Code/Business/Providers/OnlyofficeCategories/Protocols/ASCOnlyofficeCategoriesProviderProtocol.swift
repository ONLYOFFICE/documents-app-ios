//
//  ASCCategoriesProviderProtocol.swift
//  Documents
//
//  Created by Павел Чернышев on 22.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCOnlyofficeCategoriesProviderProtocol {
    var categoriesCurrentlyLoading: Bool { get }
    func loadCategories(completion: @escaping ([ASCOnlyofficeCategory]) -> Void)
}
