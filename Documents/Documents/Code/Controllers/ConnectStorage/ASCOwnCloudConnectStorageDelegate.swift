//
//  ASCOwnCloudConnectStorageDelegate.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 4/11/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation
import WebKit

final class ASCOwnCloudConnectStorageDelegate: NSObject, ASCConnectStorageOAuth2Delegate {
    var clientId: String?
    var redirectUrl: String?
    var baseURL: URL!

    var scope: String = "openid profile email offline_access"
    var responseType: String = "code id_token"

    var ownCloudApiClient: OwncloudApiClient?

    weak var viewController: ASCConnectStorageOAuth2ViewController? {
        didSet { viewController?.delegate = self }
    }

    func viewDidLoad(controller: ASCConnectStorageOAuth2ViewController) {
        guard
            let clientId,
            let redirectUrl,
            let baseURL
        else { return }

        ownCloudApiClient = OwncloudApiClient(clientId: clientId, redirectUrl: redirectUrl, baseURL: baseURL)

        guard
            let authorizeURL = OwncloudHelper.makeURL(base: baseURL, addingPath: OwncloudEndpoints.Path.authorize)
        else { return }

        var comps = URLComponents(url: authorizeURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "client_id", value: clientId),
            .init(name: "response_type", value: responseType),
            .init(name: "redirect_uri", value: redirectUrl),
            .init(name: "scope", value: scope),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge", value: ownCloudApiClient?.codeChallenge),
        ]

        guard let url = comps.url else { return }

        let req = URLRequest(url: url)
        controller.load(request: req)
    }

    func shouldStartLoad(with request: String, in controller: ASCConnectStorageOAuth2ViewController) -> Bool {
        guard let url = URL(string: request) else { return true }

        let isCallbackPath = url.path.contains(OwncloudEndpoints.Path.callbackURL)
        let isRedirectURL = (redirectUrl.flatMap { request.hasPrefix($0) } ?? false)

        guard isCallbackPath || isRedirectURL else {
            return true
        }

        var params: [String: String] = [:]

        if let fr = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment, !fr.isEmpty {
            let fake = URL(string: "https://dummy.local/?\(fr)")!
            if let items = URLComponents(url: fake, resolvingAgainstBaseURL: false)?.queryItems {
                for it in items {
                    params[it.name] = it.value ?? ""
                }
            }
        }

        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for it in items {
                params[it.name] = it.value ?? ""
            }
        }

        if let err = params["error"] {
            controller.complation?(["error": "\(err): \(params["error_description"] ?? "")"])
            return false
        }

        guard let code = params["code"], !code.isEmpty else {
            controller.complation?(["error": "missing authorization code"])
            return false
        }

        ownCloudApiClient?.exchangeCodeForTokens(code: code) { [weak controller] result in
            DispatchQueue.main.async {
                switch result {
                case let .success(token):
                    controller?.complation?([
                        "auth": "Bearer",
                        "token": token.access_token,
                        "refresh_token": token.refresh_token,
                        "expires_in": token.expires_in,
                    ])
                case let .failure(error):
                    controller?.complation?(["error": error.localizedDescription])
                }
            }
        }

        return false
    }
}
