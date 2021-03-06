//
//  ASCYandexFileProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 09/11/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import FilesProvider

class ASCYandexFileProvider: ASCWebDAVProvider {
    override var type: ASCFileProviderType {
        get {
            return .yandex
        }
    }

    override var rootFolder: ASCFolder {
        get {
            return {
                $0.title = NSLocalizedString("Yandex Disk", comment: "")
                $0.rootFolderType = .yandexAll
                $0.id = "/"
                return $0
            }(ASCFolder())
        }
    }

    private let baseUrl = URL(string: "https://webdav.yandex.ru")!

    override init() {
        super.init()
    }

    init(credential: URLCredential) {
        super.init(baseURL: baseUrl, credential: credential)
        provider?.credentialType = .basic
    }

    override func copy() -> ASCBaseFileProvider {
        let copy = ASCYandexFileProvider()
        
        copy.items = items
        copy.page = page
        copy.total = total
        copy.delegate = delegate
        copy.deserialize(serialize() ?? "")
        
        return copy
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
