//
//  ASCFileManager.swift
//  Documents
//
//  Created by Alexander Yuzhin on 12/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import KeychainSwift
import FileKit

class ASCFileManager {
    public static var provider: ASCFileProviderProtocol? {
        didSet {
            storeCurrentProvider()
        }
    }
    public static var localProvider: ASCLocalProvider = ASCLocalProvider()
    public static var onlyofficeProvider: ASCOnlyofficeProvider?
    public static var cloudProviders: [ASCFileProviderProtocol] = [] {
        didSet {
            observer.notify(observer)
        }
    }

    private static var keychain: KeychainSwift {
        get {
            let keychain = KeychainSwift()
            keychain.accessGroup = ASCConstants.Keychain.group
            keychain.synchronizable = true
            return keychain
        }
    }

    public static var observer = Event<Any?>()
    
    static func reset() {
        provider?.reset()
        localProvider.reset()
        onlyofficeProvider?.reset()
        cloudProviders.forEach { provider in
            provider.reset()
        }
    }

    static func createProvider(by type: ASCFileProviderType) -> ASCFileProviderProtocol? {
        switch type {
        case .googledrive:
            return ASCGoogleDriveProvider()
        case .dropbox:
            return ASCDropboxProvider()
        case .nextcloud:
            return ASCNextCloudProvider()
        case .owncloud:
            return ASCOwnCloudProvider()
        case .yandex:
            return ASCYandexFileProvider()
        case .webdav:
            return ASCWebDAVProvider()
        case .icloud:
            return ASCiCloudProvider()
        default:
            return nil
        }
    }

    static func storeProviders() {
        var provividersInfo: [String] = []
        var allProviders: [ASCFileProviderProtocol] = cloudProviders

        if let onlyofficeProvider = onlyofficeProvider {
            allProviders.append(onlyofficeProvider)
        }

        allProviders.forEach { provider in
            if let serializeProvider = provider.serialize() {
                provividersInfo.append(serializeProvider)
            }
        }

        // Store providers
        let provividersData = NSKeyedArchiver.archivedData(withRootObject: provividersInfo)
        keychain.set(provividersData, forKey: ASCConstants.Keychain.keyProviders)

        // Store last provider
        storeCurrentProvider()
    }

    static func loadProviders() {
        // Load providers
        if let rawData = keychain.getData(ASCConstants.Keychain.keyProviders),
            let serializedProviders = NSKeyedUnarchiver.unarchiveObject(with: rawData) as? [String] {
            cloudProviders = []

            serializedProviders.forEach { serializedProvider in
                if let jsonProvider = serializedProvider.toDictionary() {
                    let type = ASCFileProviderType(rawValue: jsonProvider["type"] as? String ?? "")

                    if type == .onlyoffice {
                        let provider = ASCOnlyofficeProvider()
                        provider.deserialize(serializedProvider)
                        onlyofficeProvider = provider
                    } else {
                        var provider: ASCFileProviderProtocol? = nil

                        switch type {
                        case .some(.googledrive):
                            provider = ASCGoogleDriveProvider()
                        case .some(.dropbox):
                            provider = ASCDropboxProvider()
                        case .some(.nextcloud):
                            provider = ASCNextCloudProvider()
                        case .some(.owncloud):
                            provider = ASCOwnCloudProvider()
                        case .some(.yandex):
                            provider = ASCYandexFileProvider()
                        case .some(.webdav):
                            provider = ASCWebDAVProvider()
                        case .some(.icloud):
                            provider = ASCiCloudProvider()
                        default:
                            break
                        }

                        if let provider = provider {
                            provider.deserialize(serializedProvider)
                            cloudProviders.append(provider)
                        }
                    }
                }
            }
        }
        
        if ASCConstants.Feature.allowiCloud {
            // iCloud Setup
            iCloudUpdate()
        }

        // Load last provider
        loadCurrentProvider()
    }

    static func storeCurrentProvider() {
        if let provider = provider, let providerIdData = (provider.id ?? "device").data(using: .utf8) {
            keychain.set(providerIdData, forKey: ASCConstants.Keychain.keyLastProviderId)
        }
    }

    static func loadCurrentProvider() {
        if let rawData = keychain.getData(ASCConstants.Keychain.keyLastProviderId),
            let currentProviderId = String(data: rawData, encoding: .utf8) {
            if let onlyofficeProvider = onlyofficeProvider, onlyofficeProvider.id == currentProviderId  {
                provider = onlyofficeProvider
            } else if let cloudProvider = cloudProviders.first(where: { $0.id == currentProviderId }) {
                provider = cloudProvider
            } else {
                provider = localProvider
            }
        } else {
            provider = localProvider
        }
    }
    
    private static func iCloudUpdate() {
        if let iCloudProvider = cloudProviders.first(where: { $0.type == .icloud }) as? ASCiCloudProvider {
            iCloudProvider.initialize { success in
                if !success, let index = cloudProviders.firstIndex(where: { $0.type == .icloud }) {
                    cloudProviders.remove(at: index)
                }
            }
        } else {
            let iCloudProvider = ASCiCloudProvider()
            iCloudProvider.initialize { success in
                if success, iCloudProvider.hasiCloudAccount {
                    cloudProviders.append(iCloudProvider)
                }
            }
        }
    }
}
