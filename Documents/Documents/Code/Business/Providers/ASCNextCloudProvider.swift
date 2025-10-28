//
//  ASCNextCloudProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 12/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import Alamofire
import FileKit
import FilesProvider
import UIKit

class ASCNextCloudProvider: ASCWebDAVProvider {
    // MARK: - Properties

    override var type: ASCFileProviderType {
        return .nextcloud
    }

    override var rootFolder: ASCFolder {
        return {
            $0.title = NSLocalizedString("Nextcloud", comment: "")
            $0.rootFolderType = .nextcloudAll
            $0.id = "/"
            return $0
        }(ASCFolder())
    }

    private var apiClient: NextcloudApiClient?
    private let webdavEndpoint = "/remote.php/dav/files"
    private let endpointPath = "/remote.php/dav/files/%@"

    override var provider: WebDAVFileProvider? {
        didSet {
            guard let provider = provider else {
                entityExistenceChecker = nil
                entityUniqNameFinder = nil
                return
            }

            entityExistenceChecker = ASCEntityExistenceCheckerByAttributes(provider: provider)
            entityUniqNameFinder = ASCEntityUniqNameFinder(entityExistChecker: entityExistenceChecker!)
        }
    }

    private var entityExistenceChecker: ASCEntityExistenceChecker?
    private var entityUniqNameFinder: ASCUniqNameFinder?

    // MARK: - Lifecycle Methods

    override init() {
        super.init()
        apiClient = nil
    }

    init(baseURL: URL, credential: URLCredential, userData: NextcloudUserData) {
        let isLDAP = userData.backend == "LDAP"
        let credentialUsername = credential.user ?? ""

        var providerUrl = baseURL

        if providerUrl.scheme == nil,
           let fixedUrl = URL(string: "https://\(providerUrl.absoluteString)")
        {
            providerUrl = fixedUrl
        }

        let userId = (isLDAP ? (userData.id ?? credentialUsername) : credentialUsername)
        let urlPath = String(format: endpointPath, userId)

        if !providerUrl.absoluteString.contains(webdavEndpoint) {
            providerUrl = URL(string: providerUrl.absoluteString.removingSuffix("/")) ?? providerUrl
            providerUrl = providerUrl.appendingPathComponent(urlPath)
        }

        super.init(baseURL: providerUrl, credential: credential)
        provider?.credentialType = .basic

        if let user = credential.user, let password = credential.password {
            apiClient = NextcloudApiClient(
                url: ((providerUrl.scheme != nil) ? "\(providerUrl.scheme!)://" : "") + "\(providerUrl.host ?? "")",
                user: user,
                password: password
            )

            setUserInfo(userData: userData)
        }
    }

    override func copy() -> ASCFileProviderProtocol {
        let copy = ASCNextCloudProvider()

        copy.items = items
        copy.page = page
        copy.total = total
        copy.delegate = delegate
        copy.deserialize(serialize() ?? "")

        return copy
    }

    override func cancel() {
        super.cancel()
        apiClient?.cancelAll()
    }

    override func deserialize(_ jsonString: String) {
        if let json = jsonString.toDictionary() {
            if let userJson = json["user"] as? [String: Any] {
                user = ASCUser(JSON: userJson)
            }

            if
                let baseUrl = URL(string: json["baseUrl"] as? String ?? ""),
                let password = json["password"] as? String,
                let user = user,
                let userId = user.userId,
                let userDisplayName = user.displayName
            {
                let credential = URLCredential(user: userDisplayName, password: password, persistence: .permanent)
                var providerUrl = baseUrl
                let urlPath = String(format: endpointPath, userId)

                if !providerUrl.absoluteString.contains(webdavEndpoint) {
                    providerUrl = providerUrl.appendingPathComponent(urlPath)
                }

                provider = WebDAVFileProvider(baseURL: providerUrl, credential: credential)
                provider?.credentialType = .basic

                apiClient = NextcloudApiClient(
                    url: ((providerUrl.scheme != nil) ? "\(providerUrl.scheme!)://" : "") + "\(providerUrl.host ?? "")",
                    user: userId,
                    password: password
                )
            }
        }
    }

    override func isReachable(with info: [String: Any], complation: @escaping ((Bool, ASCFileProviderProtocol?) -> Void)) {
        guard
            let portal = info["url"] as? String,
            let login = info["login"] as? String,
            let password = info["password"] as? String,
            let userData = info["userData"] as? NextcloudUserData,
            let portalUrl = URL(string: portal)
        else {
            complation(false, nil)
            return
        }

        let credential = URLCredential(user: login, password: password, persistence: .permanent)
        let nextCloudProvider = ASCNextCloudProvider(baseURL: portalUrl, credential: credential, userData: userData)

        nextCloudProvider.isReachable { success, error in
            DispatchQueue.main.async {
                complation(success, success ? nextCloudProvider : nil) // Need to capture nextCloudProvider variable
            }
        }
    }

    func setUserInfo(userData: NextcloudUserData) {
        user = ASCUser()
        user?.userId = userData.id
        user?.displayName = userData.displayName
    }

    /// Fetch an Array of 'ASCEntity's identifying the the directory entries via asynchronous completion handler.
    ///
    /// - Parameters:
    ///   - folder: target directory
    ///   - parameters: dictionary of settings for searching and sorting or any other information
    ///   - completeon: a closure with result of directory entries or error
    override func fetch(for folder: ASCFolder, parameters: [String: Any?], completeon: ASCProviderCompletionHandler?) {
        super.fetch(for: folder, parameters: parameters, completeon: completeon)
    }

    /// Check if we can edit the entity
    ///
    /// - Parameters:
    ///   - entity: target entity
    override func allowEdit(entity: AnyObject?) -> Bool {
        return true
    }

    override func createDocument(_ name: String, fileExtension: String, in folder: ASCFolder, completeon: ASCProviderCompletionHandler?) {
        findUniqName(suggestedName: name.appendingPathExtension(fileExtension) ?? name, inFolder: folder) { uniqName in
            super.createDocument(uniqName.removingSuffix(".\(fileExtension)"), fileExtension: fileExtension, in: folder, completeon: completeon)
        }
    }

    override func createImage(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        findUniqName(suggestedName: name, inFolder: folder) { uniqName in
            super.createImage(uniqName, in: folder, data: data, params: params, processing: processing)
        }
    }

    override func createFile(_ name: String, in folder: ASCFolder, data: Data, params: [String: Any]?, processing: @escaping NetworkProgressHandler) {
        findUniqName(suggestedName: name, inFolder: folder) { uniqName in
            super.createFile(uniqName, in: folder, data: data, params: params, processing: processing)
        }
    }

    override func createFolder(_ name: String, in folder: ASCFolder, params: [String: Any]?, completeon: ASCProviderCompletionHandler?) {
        findUniqName(suggestedName: name, inFolder: folder) { uniqName in
            super.createFolder(uniqName, in: folder, params: params, completeon: completeon)
        }
    }

    func findUniqName(suggestedName: String, inFolder folder: ASCFolder, completionHandler: @escaping (String) -> Void) {
        guard let entityUniqNameFinder = entityUniqNameFinder else {
            completionHandler(suggestedName)
            return
        }

        entityUniqNameFinder.find(bySuggestedName: suggestedName, atPath: folder.id) { uniqName in
            completionHandler(uniqName)
        }
    }
}
