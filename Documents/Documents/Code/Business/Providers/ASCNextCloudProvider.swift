//
//  ASCNextCloudProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 12/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import FilesProvider
import FileKit
import Alamofire

class ASCNextCloudProvider: ASCWebDAVProvider {

    // MARK: - Properties

    override var type: ASCFileProviderType {
        get {
            return .nextcloud
        }
    }

    override var rootFolder: ASCFolder {
        get {
            return {
                $0.title = NSLocalizedString("Nextcloud", comment: "")
                $0.rootFolderType = .nextcloudAll
                $0.id = "/"
                return $0
            }(ASCFolder())
        }
    }

    private var apiClient: NextcloudApiClient?
    private let webdavEndpoint = "/remote.php/dav/files"
    private let endpointPath = "/remote.php/dav/files/%@"

    // MARK: - Lifecycle Methods

    override init() {
        super.init()
        apiClient = nil
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

        if let user = credential.user, let password = credential.password {
            apiClient = NextcloudApiClient(
                url: ((providerUrl.scheme != nil) ? "\(providerUrl.scheme!)://" : "") + "\(providerUrl.host ?? "")",
                user: user,
                password: password
            )
            userInfo { success, error in
                log.debug("Nexcloud fetch storagestats", success, error ?? "")
            }
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
                
                apiClient = NextcloudApiClient(
                    url: ((providerUrl.scheme != nil) ? "\(providerUrl.scheme!)://" : "") + "\(providerUrl.host ?? "")",
                    user: userId,
                    password: password
                )
            }
        }
    }

    /// Fetch an user information
    ///
    /// - Parameter completeon: a closure with result of user or error
    override func userInfo(completeon: ASCProviderUserInfoHandler?) {
        guard let apiClient = apiClient else { return }

        let params = [
            "dir": "/"
        ]

        apiClient.request(NextcloudAPI.Endpoints.currentAccount, params) { [weak self] response, error in
            guard let strongSelf = self else {
                completeon?(false, nil)
                return
            }
            
            guard let account = response?.result else {
                completeon?(false, error)
                if let error = error {
                    log.debug(error)
                }
                return
            }
            
            strongSelf.user = ASCUser()
            strongSelf.user?.userId = account.owner
            strongSelf.user?.displayName = account.ownerDisplayName

            completeon?(true, nil)
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
