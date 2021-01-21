//
//  ASCOwnCloudProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import FilesProvider

class ASCOwnCloudProvider: ASCWebDAVProvider {

    // MARK: - Properties

    override var type: ASCFileProviderType {
        get {
            return .owncloud
        }
    }

    override var rootFolder: ASCFolder {
        get {
            return {
                $0.title = NSLocalizedString("ownCloud", comment: "")
                $0.rootFolderType = .owncloudAll
                $0.id = "/"
                return $0
            }(ASCFolder())
        }
    }

    private let webdavEndpoint = "/remote.php/dav/files"
    private let endpointPath = "/remote.php/dav/files/%@"

    // MARK: - Lifecycle Methods

    override init() {
        super.init()
    }

    override init(baseURL: URL, credential: URLCredential) {
        var providerUrl = baseURL

        if providerUrl.scheme == nil,
            let fixedUrl = URL(string: "https://\(providerUrl.absoluteString)") {
            providerUrl = fixedUrl
        }

        let urlPath = String(format: endpointPath, credential.user ?? "")

        if !providerUrl.absoluteString.contains(webdavEndpoint) {
            providerUrl = URL(string: providerUrl.absoluteString.removingSuffix("/")) ?? providerUrl
            providerUrl = providerUrl.appendingPathComponent(urlPath)
        }

        super.init(baseURL: providerUrl, credential: credential)
        provider?.credentialType = .basic
    }

    override func copy() -> ASCFileProviderProtocol {
        let copy = ASCOwnCloudProvider()
        
        copy.items = items
        copy.page = page
        copy.total = total
        copy.delegate = delegate
        copy.deserialize(serialize() ?? "")
        
        return copy
    }

    override func cancel() {
        super.cancel()
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
                let userId = user.userId
            {
                let credential = URLCredential(user: userId, password: password, persistence: .permanent)
                var providerUrl = baseUrl
                let urlPath = String(format: endpointPath, credential.user ?? "")

                if !providerUrl.absoluteString.contains(webdavEndpoint) {
                    providerUrl = providerUrl.appendingPathComponent(urlPath)
                }

                provider = WebDAVFileProvider(baseURL: providerUrl, credential: credential)
                provider?.credentialType = .basic
            }
        }
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
}
