//
//  ASCAccountsManage.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10/24/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import KeychainSwift

class ASCAccountsManager {
    public static let shared = ASCAccountsManager()
    
    private(set) var accounts: [ASCAccount] = []
    private let keychain = KeychainSwift()
    
    // MARK: - Private
    
    init() {
        NSKeyedUnarchiver.setClass(ASCAccount.self, forClassName: "Projects.ASCAccount")
        NSKeyedUnarchiver.setClass(ASCAccount.self, forClassName: "ASCAccount")
        NSKeyedArchiver.setClassName("ASCAccount", for: ASCAccount.self)

        NotificationCenter.default.addObserver(self, selector: #selector(onUpdateUserInfo), name: ASCConstants.Notifications.userInfoOnlyofficeUpdate, object: nil)        
        loadAccounts()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadAccounts() {
//        for index in 0..<5 {
//            if let account = ASCAccount(JSON:
//                [
//                    "email": "email \(index)",
//                    "displayName": "name \(index)",
//                    "avatar": "avatar  \(index)",
//                    "portal": "apiBaseUrl  \(index)",
//                    "token": "apiToken  \(index)"
//                ]
//                ) {
//                accounts.append(account)
//            }
//        }
//
//        return

        keychain.accessGroup = ASCConstants.Keychain.group
        keychain.synchronizable = true

        if let rawData = keychain.getData(ASCConstants.Keychain.keyAccounts),
            let array = NSKeyedUnarchiver.unarchiveObject(with: rawData) as? [ASCAccount] {
            accounts = array
        } else {
            accounts = []
        }
    }
    
    private func storeAccounts() {
        let rawData = NSKeyedArchiver.archivedData(withRootObject: accounts)
        keychain.set(rawData, forKey: ASCConstants.Keychain.keyAccounts)
    }
    
    private func index(of account: ASCAccount) -> Int? {
        return accounts.firstIndex(where: { ($0.email == account.email) && ($0.portal == account.portal) })
    }
    
    @objc func onUpdateUserInfo() {
        if
            let user = ASCFileManager.onlyofficeProvider?.user,
            let provider = ASCFileManager.onlyofficeProvider,
            let portal = provider.apiLegacy.baseUrl,
            let token = provider.apiLegacy.token
        {
            let dateTransform = ASCDateTransform()
            if let account = ASCAccount(JSON: [
                "email": user.email ?? "",
                "displayName": user.displayName ?? "",
                "avatar": user.avatarRetina ?? user.avatar ?? "",
                "portal": portal,
                "token": token,
                "expires": dateTransform.transformToJSON(provider.apiLegacy.expires) ?? ""
                ])
            {
                add(account)
            }
        }
    }
    
    // MARK: - Public

    /// Add new account or update exist
    ///
    /// - Parameter account: New account object
    func add(_ account: ASCAccount) {
        if let index = index(of: account) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
        storeAccounts()
    }

    /// Remove exist account
    ///
    /// - Parameter account: Exist account object
    func remove(_ account: ASCAccount) {
        if let index = index(of: account) {
            accounts.remove(at: index)
            storeAccounts()
        }
    }
    
    /// Update exist account
    ///
    /// - Parameter account: Search exist record to update by 'id' and 'portal' properties of ASCAccount object
    func update(_ account: ASCAccount) {
        if let index = index(of: account) {
            accounts[index] = account
            storeAccounts()
        }
    }

    /// Returns the account by portal address and email
    ///
    /// - Parameters:
    ///     - portal: Portal address
    ///     - email: User email
    ///
    /// - Returns: An account record
    func get(by portal: String, email: String) -> ASCAccount? {
        return accounts.first(where: { ($0.email == email) && ($0.portal == portal) })
    }
}
