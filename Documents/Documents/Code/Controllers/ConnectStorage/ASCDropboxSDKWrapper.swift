//
//  ASCDropboxSDKWrapper.swift
//  Documents
//
//  Created by Alexander Yuzhin on 19.06.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import SwiftyDropbox
import UIKit

final class ASCDropboxSDKWrapper {
    static let shared = ASCDropboxSDKWrapper()

    typealias ASCDropboxSDKLoginComplate = ([String: Any]) -> Void

    private let defaultScope = [
        "account_info.read",
        "files.content.read",
        "files.metadata.read",
        "files.content.write",
    ]
    private var providerKey = ASCFolderProviderType.dropBox.rawValue
    private var loginComplation: ASCDropboxSDKLoginComplate?

    /// Login via Dropbox SDK
    /// - Parameters:
    ///   - controller: Parent ViewController for present
    ///   - scopes: List of scopes
    ///   - complation: Login complation handler
    func login(at controller: UIViewController, with scopes: [String]? = nil, complation: @escaping ASCDropboxSDKLoginComplate) {
        loginComplation = complation

        let scopeRequest = ScopeRequest(scopeType: .user, scopes: scopes ?? defaultScope, includeGrantedScopes: false)
        DropboxClientsManager.authorizeFromControllerV2(
            UIApplication.shared,
            controller: controller,
            loadingStatusDelegate: nil,
            openURL: { (url: URL) in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            },
            scopeRequest: scopeRequest
        )
    }

    /// Redirect handle from Dropbox SDK
    /// - Parameter authResult: Result of authorization
    func handleOAuthRedirect(_ authResult: DropboxOAuthResult?) {
        if let result = authResult {
            switch result {
            case let .success(token):
                log.debug("Success! User is logged into DropboxClientsManager.")
                loginComplation?([
                    "providerKey": providerKey,
                    "token": token.accessToken,
                    "refresh_token": token.refreshToken ?? "",
                    "expires_in": Int(Date(timeIntervalSince1970: token.tokenExpirationTimestamp ?? 0).timeIntervalSinceNow),
                    "uid": token.uid,
                ])
            case .cancel:
                loginComplation?([
                    "error": "Authorization flow was manually canceled by user!",
                ])
            case let .error(_, description):
                loginComplation?([
                    "error": "Error: \(String(describing: description))",
                ])
            }
        }
    }
}
