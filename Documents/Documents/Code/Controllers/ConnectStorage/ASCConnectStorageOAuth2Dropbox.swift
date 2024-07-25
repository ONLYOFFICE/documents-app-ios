//
//  ASCConnectStorageOAuth2Dropbox.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/16/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Alamofire
import ObjectMapper
import UIKit

class ASCConnectStorageOAuth2Dropbox: ASCConnectStorageOAuth2Delegate {
    struct AuthByCodeResponseModel: Mappable {
        var providerKey = ASCFolderProviderType.dropBox.rawValue

        var accessToken: String = ""
        var expiresIn: Int = 0
        var tokenType: String = ""
        var scope: String = ""
        var refreshToken: String = ""
        var accountId: String = ""
        var uid: String = ""
        var dict: [String: Any] { [
            "providerKey": providerKey,
            "access_token": accessToken,
            "token": accessToken,
            "expires_in": expiresIn,
            "token_type": tokenType,
            "scope": scope,
            "refresh_token": refreshToken,
            "account_id": accountId,
            "uid": uid,
        ] }

        init?(map: Map) {}

        mutating func mapping(map: Map) {
            accessToken <- map["access_token"]
            expiresIn <- map["expires_in"]
            tokenType <- map["token_type"]
            scope <- map["scope"]
            refreshToken <- map["refresh_token"]
            accountId <- map["account_id"]
            uid <- map["uid"]
        }
    }

    struct RefreshTokenResponseModel: Mappable {
        var accessToken: String = ""
        var expiresIn: Int = 0
        var tokenType: String = ""

        init?(map: Map) {}

        mutating func mapping(map: Map) {
            accessToken <- map["access_token"]
            expiresIn <- map["expires_in"]
            tokenType <- map["token_type"]
        }
    }

    // MARK: - Properties

    weak var viewController: ASCConnectStorageOAuth2ViewController? {
        didSet {
            viewController?.delegate = self
        }
    }

    var clientId: String?
    var clientSecret: String?
    var redirectUrl: String?

    // MARK: - ASCConnectStorageOAuth2 Delegate

    func viewDidLoad(controller: ASCConnectStorageOAuth2ViewController) {
        let parameters: [String: String] = [
            "response_type": "code",
            "token_access_type": "offline",
            "client_id": clientId ?? "",
            "redirect_uri": redirectUrl ?? "",
            "force_reauthentication": "true",
        ]

        let authRequest = "https://www.dropbox.com/oauth2/authorize?\(parameters.stringAsHttpParameters())"
        let urlRequest = URLRequest(url: URL(string: authRequest)!)

        let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1"

        UserDefaults.standard.register(defaults: ["UserAgent": customUserAgent])

        controller.webView?.customUserAgent = customUserAgent
        controller.load(request: urlRequest)
    }

    func shouldStartLoad(with request: String, in controller: ASCConnectStorageOAuth2ViewController) -> Bool {
        log.info("webview url = \(request)")

        if let errorMessage = controller.getQueryStringParameter(url: request, param: "error") {
            handleError(controller: controller, errorMessage: errorMessage)
            return false
        }

        guard let redirectUrl = redirectUrl, request.contains(redirectUrl),
              let code = controller.getQueryStringParameter(url: request, param: "code") else { return true }

        switch controller.responseType {
        case .code:
            controller.complation?([
                "providerKey": ASCFolderProviderType.dropBox.rawValue,
                "token": code,
            ])
        case .token:
            accessToken(byCode: code) { result in
                switch result {
                case let .success(model):
                    controller.complation?(model.dict)
                case let .failure(error):
                    self.handleError(controller: controller, errorMessage: error.localizedDescription)
                }
            }
        }

        return false
    }

    func accessToken(with refreshToken: String, completion: @escaping (Result<RefreshTokenResponseModel, Error>) -> Void) {
        let parameters: Parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
        ]

        request(parameters: parameters, completion: completion)
    }

    private func accessToken(byCode code: String, completion: @escaping (Result<AuthByCodeResponseModel, Error>) -> Void) {
        let parameters: Parameters = [
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUrl ?? "",
        ]

        request(parameters: parameters, completion: completion)
    }

    private func request<T: BaseMappable>(parameters: Parameters, completion: @escaping (Result<T, Error>) -> Void) {
        let tokenEndpoint: Endpoint<T> = Endpoint<T>.make(DropboxAPI.Path.token, .post, URLEncoding.httpBody)
        let client = NetworkingClient()
        client.configure(url: DropboxAPI.URL.api)
        client.headers.add(baseAuthHeader())
        client.headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
        client.request(tokenEndpoint, parameters) { result, error in
            guard let result = result else {
                if let error = error {
                    log.error(error)
                    completion(.failure(error))
                } else {
                    completion(.failure(NetworkingError.unknown(error: error)))
                }
                return
            }

            log.info(result)
            completion(.success(result))
        }
    }

    private func handleError(controller: ASCConnectStorageOAuth2ViewController, errorMessage: String) {
        log.error("code: \(errorMessage)")

        if let topViewController = controller.navigationController?.topViewController {
            UIAlertController.showError(
                in: topViewController,
                message: String(format: NSLocalizedString("Please retry. \n\n If the problem persists contact us and mention this error code: Dropbox - %@", comment: ""), errorMessage)
            )
            controller.navigationController?.popViewController(animated: true)
            controller.complation?([:])
        }
    }

    private func baseAuthHeader() -> HTTPHeader {
        let defaultResult = HTTPHeader(name: "Authorization", value: "Basic failure")
        guard let clientId = clientId, let clientSecret = clientSecret else {
            log.error("Client id or client secret is not set")
            return defaultResult
        }
        guard let credentialData = "\(clientId):\(clientSecret)".data(using: .utf8) else {
            log.error("Couldn't cast credintial to data with utf8")
            return defaultResult
        }
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return HTTPHeader(name: "Authorization", value: "Basic \(base64Credentials)")
    }
}
