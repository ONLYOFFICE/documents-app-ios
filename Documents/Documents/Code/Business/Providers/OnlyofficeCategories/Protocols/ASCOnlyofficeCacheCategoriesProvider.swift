//
//  ASCOnlyOfficeCacheCategoriesProvider.swift
//  Documents
//
//  Created by Павел Чернышев on 21.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCOnlyofficeCacheCategoriesProvider {
    func save(for account: ASCAccount, categories: [ASCOnlyofficeCategory]) -> Error?
    func getCategories(for account: ASCAccount) -> [ASCOnlyofficeCategory]
    func clearCache()
}
