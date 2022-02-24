//
//  ASCFileManager.swift
//  Documents
//
//  Created by Alexander Yuzhin on 12/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import FileKit
import KeychainSwift
import UIKit

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
        let keychain = KeychainSwift()
        keychain.accessGroup = ASCConstants.Keychain.group
        keychain.synchronizable = true
        return keychain
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
        case .unknown: return nil
        case .local: return ASCLocalProvider()
        case .onlyoffice: return ASCOnlyofficeProvider()
        case .webdav: return ASCWebDAVProvider()
        case .nextcloud: return ASCNextCloudProvider()
        case .owncloud: return ASCOwnCloudProvider()
        case .yandex: return ASCYandexFileProvider()
        case .dropbox: return ASCDropboxProvider()
        case .googledrive: return ASCGoogleDriveProvider()
        case .icloud: return ASCiCloudProvider()
        case .onedrive: return ASCOneDriveProvider()
        case .kdrive: return ASCKdriveFileProvider()
        }
    }

    static func createProvider(by folderType: ASCFolderProviderType) -> ASCFileProviderProtocol? {
        switch folderType {
        case .boxNet: return nil
        case .dropBox: return ASCDropboxProvider()
        case .google: return ASCGoogleDriveProvider()
        case .googleDrive: return ASCGoogleDriveProvider()
        case .sharePoint: return nil
        case .skyDrive: return nil
        case .oneDrive: return ASCOneDriveProvider()
        case .webDav: return ASCWebDAVProvider()
        case .yandex: return ASCYandexFileProvider()
        case .nextCloud: return ASCNextCloudProvider()
        case .ownCloud: return ASCOwnCloudProvider()
        case .iCloud: return ASCiCloudProvider()
        case .kDrive: return ASCKdriveFileProvider()
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
           let serializedProviders = NSKeyedUnarchiver.unarchiveObject(with: rawData) as? [String]
        {
            cloudProviders = []

            serializedProviders.forEach { serializedProvider in
                if let jsonProvider = serializedProvider.toDictionary(),
                   let type = ASCFileProviderType(rawValue: jsonProvider["type"] as? String ?? ""),
                   let provider = ASCFileManager.createProvider(by: type)
                {
                    provider.deserialize(serializedProvider)

                    if let onlyofficeProvider = provider as? ASCOnlyofficeProvider {
                        self.onlyofficeProvider = onlyofficeProvider
                    } else {
                        cloudProviders.append(provider)
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
           let currentProviderId = String(data: rawData, encoding: .utf8)
        {
            if let onlyofficeProvider = onlyofficeProvider, onlyofficeProvider.id == currentProviderId {
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

    class func documentTemplatePath(
        with fileExtension: String,
        languageCode: String = Locale.current.languageCode ?? "en",
        regionCode: String = Locale.current.regionCode ?? "US"
    ) -> String? {
        let resourcePath = Path(Bundle.main.resourcePath ?? "")
        let preferredLanguage = "\(languageCode)-\(regionCode)"
        let templateDirectoryRoot = "new"
        let templateFileName = "new.\(fileExtension)"
        let templateDirectoryList = (resourcePath + templateDirectoryRoot).find { $0.fileName }

        let templateDirectory =
            templateDirectoryList.first { $0 == preferredLanguage } ?? // [language designator]-[region designator]
            templateDirectoryList.first { $0[safe: 0 ..< 2] == preferredLanguage[safe: 0 ..< 2] } ?? // [language designator]
            "en-US"

        let templatePath = resourcePath + templateDirectoryRoot + templateDirectory + templateFileName

        if templatePath.exists {
            return templatePath.standardRawValue
        }

        return nil
    }

    // MARK: - Internal

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
