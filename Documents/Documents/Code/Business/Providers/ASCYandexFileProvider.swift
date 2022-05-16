//
//  ASCYandexFileProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 09/11/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import FilesProvider
import UIKit

class ASCYandexFileProvider: ASCWebDAVProvider {
    override var type: ASCFileProviderType {
        return .yandex
    }

    override var rootFolder: ASCFolder {
        return {
            $0.title = NSLocalizedString("Yandex Disk", comment: "")
            $0.rootFolderType = .yandexAll
            $0.id = "/"
            return $0
        }(ASCFolder())
    }

    private let baseUrl = URL(string: "https://webdav.yandex.ru")!

    override init() {
        super.init()
    }

    init(credential: URLCredential) {
        super.init(baseURL: baseUrl, credential: credential)
        provider?.credentialType = .basic
    }

    override func copy() -> ASCFileProviderProtocol {
        let copy = ASCYandexFileProvider()

        copy.items = items
        copy.page = page
        copy.total = total
        copy.delegate = delegate
        copy.deserialize(serialize() ?? "")

        return copy
    }

    override func isReachable(with info: [String: Any], complation: @escaping ((Bool, ASCFileProviderProtocol?) -> Void)) {
        guard
            let login = info["login"] as? String,
            let password = info["password"] as? String
        else {
            complation(false, nil)
            return
        }

        let credential = URLCredential(user: login, password: password, persistence: .permanent)
        let yandexCloudProvider = ASCYandexFileProvider(credential: credential)
        let rootFolder: ASCFolder = {
            $0.title = NSLocalizedString("All Files", comment: "Category title")
            $0.rootFolderType = .yandexAll
            $0.id = "/"
            return $0
        }(ASCFolder())

        yandexCloudProvider.fetch(for: rootFolder, parameters: [:]) { provider, folder, success, error in
            DispatchQueue.main.async {
                complation(success, success ? yandexCloudProvider : nil)
            }
        }
    }

    override func deserialize(_ jsonString: String) {
        if let json = jsonString.toDictionary() {
            if let userJson = json["user"] as? [String: Any] {
                user = ASCUser(JSON: userJson)
            }

            if
                let password = json["password"] as? String,
                let user = user,
                let userId = user.userId
            {
                let credential = URLCredential(user: userId, password: password, persistence: .permanent)
                provider = WebDAVFileProvider(baseURL: baseUrl, credential: credential)
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
}
