//
//  ASCYandexFileProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 09/11/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import FilesProvider
import UIKit
import YandexLoginSDK

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
    private let apiURL = URL(string: "https://login.yandex.ru/info")!

    override init() {
        super.init()
    }

    init(credential: URLCredential) {
        super.init(baseURL: baseUrl, credential: credential)
        provider?.credentialType = .oAuth1

        if let token = credential.password {
            DispatchQueue.main.async {
                self.userInfo(apiURL: self.apiURL, token: token)
            }
        }
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
            let token = info["token"] as? String
        else {
            complation(false, nil)
            return
        }
        let credential = URLCredential(user: "", password: token, persistence: .permanent)
        let yandexCloudProvider = ASCYandexFileProvider(credential: credential)
        let rootFolder: ASCFolder = {
            $0.title = NSLocalizedString("All Files", comment: "Category title")
            $0.rootFolderType = .yandexAll
            $0.id = "/"
            return $0
        }(ASCFolder())

        yandexCloudProvider.fetch(for: rootFolder, parameters: [:]) { provider, folder, success, error in
            DispatchQueue.main.async {
                do {
                    try YandexLoginSDK.shared.logout()
                } catch {
                    print("failed to logout")
                }
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
                let userName = user?.displayName
            {
                let credential = URLCredential(user: userName, password: password, persistence: .permanent)
                provider = WebDAVFileProvider(baseURL: baseUrl, credential: credential)
                provider?.credentialType = .oAuth1
            }
        }
    }

    func userInfo(apiURL: URL, token: String) {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")

        let task = provider?.session.dataTask(with: request, completionHandler: { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 400
            if status >= 400, let code = FileProviderHTTPErrorCode(rawValue: status) {
                let errorDesc = data.flatMap { String(data: $0, encoding: .utf8) }
                return
            }
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let login = json["login"] as? String,
                       let id = json["id"] as? String,
                       let firstName = json["first_name"] as? String,
                       let lastName = json["last_name"] as? String,
                       let realName = json["real_name"] as? String
                    {
                        self.user = ASCUser()
                        self.user?.displayName = login
                        self.user?.userId = id
                        self.user?.department = NSLocalizedString("Yandex Disk", comment: "")
                        return
                    } else {
                        return
                    }
                } catch {
                    return
                }
            }
        })
        task?.resume()
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
