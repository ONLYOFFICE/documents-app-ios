//
//  ASCConnectStorageOAuth2Dropbox.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/16/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire

class ASCConnectStorageOAuth2Dropbox: ASCConnectStorageOAuth2Delegate {
    
    struct AuthByCodeResponseModel: Codable {
        var access_token: String
        var expires_in: Int
        var token_type: String
        var scope: String
        var refresh_token: String
        var account_id: String
        var uid: String
        var dict: [String: Any] {[
            "access_token": self.access_token,
            "expires_in": self.expires_in,
            "token_type": self.token_type,
            "scope": self.scope,
            "refresh_token": self.refresh_token,
            "account_id": self.account_id,
            "uid": self.uid,
        ]}
    }
    
    struct RefreshTokenResponseModel: Codable {
        var access_token: String
        var expires_in: Int
        var token_type: String
    }

    // MARK: - Properties

    weak var viewController: ASCConnectStorageOAuth2ViewController? {
        didSet {
            viewController?.delegate = self
        }
    }

    var clientId: String?
    var redirectUrl: String?

    var clientSecret: String?
    
    let tokenUrl = "https://api.dropboxapi.com/oauth2/token"
    
    // MARK: - ASCConnectStorageOAuth2 Delegate

    func viewDidLoad(controller: ASCConnectStorageOAuth2ViewController) {
        let parameters: [String: String] = [
            "response_type": controller.responseType == .code ? "code" : "token",
            "token_access_type": "offline",
            "client_id": clientId ?? "",
            "redirect_uri": redirectUrl ?? "",
            "force_reauthentication": "true",
        ]

        let authRequest = "https://www.dropbox.com/oauth2/authorize?\(parameters.stringAsHttpParameters())"
        let urlRequest = URLRequest(url: URL(string: authRequest)!)

        let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/603.1.23 (KHTML, like Gecko) Version/10.0 Mobile/14E5239e Safari/602.1"

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

        if let redirectUrl = redirectUrl, request.contains(redirectUrl) {
            if controller.responseType == .code {
                if let code = controller.getQueryStringParameter(url: request, param: "code") {
                    accessToken(byCode: code) {  result in
                        switch result {
                        case let .success(model):
                            var dict = model.dict
                            dict["providerKey"] = ASCFolderProviderType.dropBox.rawValue
                            dict["token"] = model.access_token
                            controller.complation?(dict)
                        case let .failure(error):
                            self.handleError(controller: controller, errorMessage: error.localizedDescription)
                        }
                    }
                    return false
                }
            } else {
                var correctRequest = request

                if request.contains(redirectUrl + "#") {
                    correctRequest = request.replacingOccurrences(of: redirectUrl + "#", with: redirectUrl + "?")
                }

                if let token = controller.getQueryStringParameter(url: correctRequest, param: "access_token") {
                    controller.complation?([
                        "providerKey": ASCFolderProviderType.dropBox.rawValue,
                        "token": token,
                    ])
                    return false
                }
            }
        }

        return true
    }
    
    func accessToken(with refreshToken: String, completion: @escaping (Result<RefreshTokenResponseModel, Error>) -> Void) {
        let parameters: Parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        let httpHeaders = HTTPHeaders([
            baseAuthHeader(),
            HTTPHeader(name: "Content-Type", value: "application/x-www-form-urlencoded")
        ])
        
        request(parameters: parameters, httpHeaders: httpHeaders, completion: completion)
    }
    
    private func accessToken(byCode code: String, completion: @escaping (Result<AuthByCodeResponseModel, Error>) -> Void) {
        let parameters: Parameters = [
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUrl ?? "",
        ]
        let httpHeaders = HTTPHeaders([
            baseAuthHeader(),
            HTTPHeader(name: "Content-Type", value: "application/x-www-form-urlencoded")
        ])
        
        request(parameters: parameters, httpHeaders: httpHeaders, completion: completion)
    }
    
    private func request<T: Codable>(parameters: Parameters, httpHeaders: HTTPHeaders, completion: @escaping (Result<T, Error>) -> Void) {
        AF.request(
            tokenUrl,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.httpBody,
            headers: httpHeaders
        ).responseDecodable(of: T.self) { response in
            switch response.result {
            case .success(let model):
                log.info(model)
                completion(.success(model))
            case .failure(let error):
                log.error(error)
                completion(.failure(error))
            }
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
        return  HTTPHeader(name: "Authorization", value: "Basic \(base64Credentials)")
    }
}
