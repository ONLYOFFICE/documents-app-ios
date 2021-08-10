//
//  ASCOnlyOfficeUserDefaultsCacheCategoriesProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 21.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeUserDefaultsCacheCategoriesProvider {
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public func getKey(for account: ASCAccount) -> String? {
        guard let email = account.email,
              let portal = account.portal,
              !email.isEmpty,
              !portal.isEmpty
        else {
            return nil
        }
        return "\(ASCConstants.CacheKeys.onlyofficeCategoriesPrefix)_\(email)_\(portal)"
    }
}

extension ASCOnlyofficeUserDefaultsCacheCategoriesProvider: ASCOnlyofficeCacheCategoriesProvider {
    
    func save(for account: ASCAccount, categories: [ASCOnlyofficeCategory]) -> Error? {
        guard let key = getKey(for: account) else {
            return nil
        }
        
        do {
            let data = try self.encoder.encode(categories)
        
            UserDefaults.standard.setValue(data, forKey: key)
        } catch let error {
            return error
        }
        return nil
    }
    
    func getCategories(for account: ASCAccount) -> [ASCOnlyofficeCategory] {
        guard let key = getKey(for: account), let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        do {
            return try self.decoder.decode([ASCOnlyofficeCategory].self, from: data)
        } catch {
            return []
        }
    }
    
    func clearCache() {
        UserDefaults.standard.dictionaryRepresentation().keys
            .filter({ $0.hasPrefix(ASCConstants.CacheKeys.onlyofficeCategoriesPrefix) })
            .forEach({ UserDefaults.standard.removeObject(forKey: $0) })
    }
}
