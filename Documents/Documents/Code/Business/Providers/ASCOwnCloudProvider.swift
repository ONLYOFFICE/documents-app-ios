//
//  ASCOwnCloudProvider.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import FilesProvider
import UIKit

class ASCOwnCloudProvider: ASCWebDAVProvider {
    // MARK: - Types

    private enum AuthType: String {
        case basic = "Basic"
        case bearer = "Bearer"
    }

    private enum Constants {
        static let webdavEndpoint = "/remote.php/dav/files"
        static let endpointPathFormat = "/remote.php/dav/files/%@"
        static let defaultScheme = "https"
    }

    // MARK: - Properties

    override var type: ASCFileProviderType {
        .owncloud
    }

    override var rootFolder: ASCFolder {
        let folder = ASCFolder()
        folder.title = NSLocalizedString("ownCloud", comment: "")
        folder.rootFolderType = .owncloudAll
        folder.id = "/"
        return folder
    }

    private var apiClient: OwncloudApiClient?

    // MARK: - Lifecycle Methods

    override init() {
        super.init()
    }

    init?(baseURL: URL, credential: URLCredential, userData: [String: Any]) {
        guard let authString = userData["auth"] as? String,
              let authType = AuthType(rawValue: authString)
        else {
            return nil
        }

        let normalizedURL = Self.normalizeURL(baseURL, withCredential: credential)
        super.init(baseURL: normalizedURL, credential: credential)

        configureAuthentication(authType: authType, userData: userData, baseURL: baseURL)
    }

    // MARK: - Private Methods

    private static func normalizeURL(_ baseURL: URL, withCredential credential: URLCredential) -> URL {
        var url = baseURL

        // Ensure URL has a scheme
        if url.scheme == nil, let fixedURL = URL(string: "\(Constants.defaultScheme)://\(url.absoluteString)") {
            url = fixedURL
        }

        // Add WebDAV endpoint if not present
        if !url.absoluteString.contains(Constants.webdavEndpoint) {
            let urlPath = String(format: Constants.endpointPathFormat, credential.user ?? "")
            let baseString = url.absoluteString.hasSuffix("/")
                ? String(url.absoluteString.dropLast())
                : url.absoluteString

            if let baseURL = URL(string: baseString) {
                url = baseURL.appendingPathComponent(urlPath)
            }
        }

        return url
    }

    private func configureAuthentication(authType: AuthType, userData: [String: Any], baseURL: URL) {
        switch authType {
        case .basic:
            provider?.credentialType = .basic

        case .bearer:
            provider?.credentialType = .oAuth2
            configureOAuthClient(userData: userData, baseURL: baseURL)
        }
    }

    private func configureOAuthClient(userData: [String: Any], baseURL: URL) {
        let accessToken = userData["token"] as? String ?? ""
        let refreshToken = userData["refresh_token"] as? String ?? ""
        let expires = userData["expires_in"] as? Date ?? Date()

        let redirectURL = OwncloudHelper.makeURL(
            base: baseURL,
            addingPath: OwncloudEndpoints.Path.redirectURL
        )?.absoluteString

        apiClient = OwncloudApiClient(
            clientId: OwncloudEndpoints.ClientId.web,
            redirectUrl: redirectURL,
            baseURL: baseURL
        )

        apiClient?.credential = ASCOAuthCredential(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiration: expires
        )
    }

    // MARK: - Protocol Methods

    override func copy() -> ASCFileProviderProtocol {
        let copy = ASCOwnCloudProvider()
        copy.items = items
        copy.page = page
        copy.total = total
        copy.delegate = delegate

        if let serialized = serialize() {
            copy.deserialize(serialized)
        }

        return copy
    }

    override func cancel() {
        super.cancel()
    }

    override func serialize() -> String? {
        var info: [String: Any] = ["type": type.rawValue]

        // Serialize authentication
        serializeAuthentication(into: &info)

        // Serialize user
        serializeUser(into: &info)

        // Serialize ID
        if let id = id {
            info["id"] = id
        }

        return info.jsonString()
    }

    private func serializeAuthentication(into info: inout [String: Any]) {
        if provider?.credentialType == .oAuth2, let credential = apiClient?.credential {
            info["auth"] = AuthType.bearer.rawValue
            info["token"] = credential.accessToken
            info["refresh_token"] = credential.refreshToken
            info["expires_in"] = credential.expiration.timeIntervalSince1970
            info["baseUrl"] = apiClient?.baseURL.absoluteString
        } else {
            info["auth"] = AuthType.basic.rawValue

            // Serialize base URL
            if let baseURLString = provider?.baseURL?.absoluteString {
                let trimmedBase = baseURLString.hasSuffix("/")
                    ? String(baseURLString.dropLast())
                    : baseURLString
                info["baseUrl"] = trimmedBase
            }

            // Serialize password
            if let password = provider?.credential?.password {
                info["password"] = password
            }
        }
    }

    private func serializeUser(into info: inout [String: Any]) {
        let userToSerialize: ASCUser

        if let existingUser = user {
            userToSerialize = existingUser
        } else {
            userToSerialize = ASCUser()
            userToSerialize.userId = provider?.credential?.user
            userToSerialize.displayName = userToSerialize.userId
        }

        info["user"] = userToSerialize.toJSON()
    }

    override func deserialize(_ jsonString: String) {
        guard let json = jsonString.toDictionary(),
              let authString = json["auth"] as? String,
              let authType = AuthType(rawValue: authString),
              let userJSON = json["user"] as? [String: Any],
              let user = ASCUser(JSON: userJSON),
              let userId = user.userId,
              let baseURLString = json["baseUrl"] as? String,
              let baseURL = URL(string: baseURLString)
        else {
            return
        }

        self.user = user

        let password = json["password"] as? String ?? json["token"] as? String ?? ""
        let credential = URLCredential(user: userId, password: password, persistence: .permanent)

        let providerURL = buildProviderURL(baseURL: baseURL, credential: credential)

        switch authType {
        case .basic:
            configureBasicAuth(providerURL: providerURL, credential: credential)

        case .bearer:
            configureBearerAuth(
                providerURL: providerURL,
                credential: credential,
                baseURL: baseURL,
                json: json
            )
        }
    }

    private func buildProviderURL(baseURL: URL, credential: URLCredential) -> URL {
        var url = baseURL

        if !url.absoluteString.contains(Constants.webdavEndpoint) {
            let urlPath = String(format: Constants.endpointPathFormat, credential.user ?? "")
            url = url.appendingPathComponent(urlPath)
        }

        return url
    }

    private func configureBasicAuth(providerURL: URL, credential: URLCredential) {
        provider = WebDAVFileProvider(baseURL: providerURL, credential: credential)
        provider?.credentialType = .basic
    }

    private func configureBearerAuth(
        providerURL: URL,
        credential: URLCredential,
        baseURL: URL,
        json: [String: Any]
    ) {
        let redirectURL = OwncloudHelper.makeURL(
            base: baseURL,
            addingPath: OwncloudEndpoints.Path.redirectURL
        )?.absoluteString

        let accessToken = json["token"] as? String ?? ""
        let refreshToken = json["refresh_token"] as? String ?? ""

        guard let expiresIn = json["expires_in"] as? Double else { return }

        let expirationDate = Date(timeIntervalSince1970: expiresIn)

        apiClient = OwncloudApiClient(
            clientId: OwncloudEndpoints.ClientId.web,
            redirectUrl: redirectURL,
            baseURL: baseURL
        )

        apiClient?.credential = ASCOAuthCredential(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiration: expirationDate
        )

        provider = WebDAVFileProvider(baseURL: providerURL, credential: credential)
        provider?.credentialType = .oAuth2
    }

    override func isReachable(
        with info: [String: Any],
        complation: @escaping ((Bool, ASCFileProviderProtocol?) -> Void)
    ) {
        guard let portal = info["url"] as? String,
              let authString = info["auth"] as? String,
              let authType = AuthType(rawValue: authString),
              let portalURL = URL(string: portal)
        else {
            complation(false, nil)
            return
        }

        guard let credential = buildCredential(authType: authType, info: info) else {
            complation(false, nil)
            return
        }

        let ownCloudProvider = ASCOwnCloudProvider(
            baseURL: portalURL,
            credential: credential,
            userData: info
        )

        ownCloudProvider?.isReachable { success, error in
            DispatchQueue.main.async {
                complation(success, success ? ownCloudProvider : nil)
            }
        }
    }

    private func buildCredential(authType: AuthType, info: [String: Any]) -> URLCredential? {
        guard let login = info["login"] as? String else { return nil }

        switch authType {
        case .basic:
            guard let password = info["password"] as? String else { return nil }
            return URLCredential(user: login, password: password, persistence: .permanent)

        case .bearer:
            guard let token = info["token"] as? String else { return nil }
            return URLCredential(user: login, password: token, persistence: .forSession)
        }
    }

    func fetchFromSuper(
        for folder: ASCFolder,
        parameters: [String: Any?],
        completeon: ASCProviderCompletionHandler?
    ) {
        super.fetch(for: folder, parameters: parameters, completeon: completeon)
    }

    /// Fetch an Array of 'ASCEntity's identifying the the directory entries via asynchronous completion handler.
    ///
    /// - Parameters:
    ///   - folder: target directory
    ///   - parameters: dictionary of settings for searching and sorting or any other information
    ///   - completeon: a closure with result of directory entries or error
    override func fetch(
        for folder: ASCFolder,
        parameters: [String: Any?],
        completeon: ASCProviderCompletionHandler?
    ) {
        guard provider?.credentialType == .oAuth2 else {
            super.fetch(for: folder, parameters: parameters, completeon: completeon)
            return
        }

        guard let refreshToken = apiClient?.credential?.refreshToken else { return }

        provider?.isReachable { [weak self] isUp, error in
            guard let self = self else { return }

            if isUp {
                self.fetchFromSuper(for: folder, parameters: parameters, completeon: completeon)
                return
            }

            if let webDavError = error as? FileProviderWebDavError,
               webDavError.code == .unauthorized
            {
                self.refreshTokenAndRetry(
                    refreshToken: refreshToken,
                    folder: folder,
                    parameters: parameters,
                    completeon: completeon
                )
            }
        }
    }

    private func refreshTokenAndRetry(
        refreshToken: String,
        folder: ASCFolder,
        parameters: [String: Any?],
        completeon: ASCProviderCompletionHandler?
    ) {
        apiClient?.refreshToken(refreshToken: refreshToken) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(newCredential):
                self.apiClient?.credential = newCredential
                self.provider?.credential = URLCredential(
                    user: "",
                    password: newCredential.accessToken,
                    persistence: .forSession
                )
                self.fetchFromSuper(for: folder, parameters: parameters, completeon: completeon)

            case let .failure(error):
                print("Failed to refresh token: \(error.localizedDescription)")
            }
        }
    }

    /// Check if we can edit the entity
    ///
    /// - Parameters:
    ///   - entity: target entity
    override func allowEdit(entity: AnyObject?) -> Bool {
        true
    }
}
