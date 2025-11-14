//
//  OwncloudApiClient.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 4/11/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

class OwncloudApiClient {
    var credential: ASCOAuthCredential?

    var clientId: String?
    var redirectUrl: String?
    var baseURL: URL!

    /// PKCE
    private lazy var codeVerifier: String = OwncloudHelper.randomPKCEVerifier()
    lazy var codeChallenge: String = OwncloudHelper.codeChallenge(from: codeVerifier)

    init(clientId: String?, redirectUrl: String?, baseURL: URL!) {
        self.clientId = clientId
        self.redirectUrl = redirectUrl
        self.baseURL = baseURL
    }

    // MARK: - Token exchange

    func exchangeCodeForTokens(code: String, completion: @escaping (Result<AuthByCodeResponseModel, Error>) -> Void) {
        guard
            let clientId,
            let redirectUrl,
            let tokenURL = OwncloudHelper.makeURL(base: baseURL, addingPath: OwncloudEndpoints.Path.token)
        else {
            completion(.failure(NSError(domain: "OIDC", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bad config"])))
            return
        }

        let params: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectUrl,
            "client_id": clientId,
            "code_verifier": codeVerifier,
        ]

        AF.request(
            tokenURL,
            method: .post,
            parameters: params,
            encoder: URLEncodedFormParameterEncoder.default,
            headers: ["Content-Type": "application/x-www-form-urlencoded"]
        )
        .validate(statusCode: 200 ..< 300)
        .responseDecodable(of: AuthByCodeResponseModel.self) { response in
            switch response.result {
            case let .success(token):
                DispatchQueue.main.async {
                    completion(.success(token))
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func accessToken(with refreshToken: String, complation: @escaping (Result<AuthByCodeResponseModel, Error>) -> Void) {
        guard let clientId, let redirectUrl,
              let tokenURL = OwncloudHelper.makeURL(base: baseURL, addingPath: OwncloudEndpoints.Path.token)
        else { return }
        let parameters: Parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "redirect_uri": redirectUrl,
            "client_id": clientId,
        ]

        let httpHeaders = HTTPHeaders(["Content-Type": "application/x-www-form-urlencoded"])

        AF.request(
            tokenURL,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.httpBody,
            headers: httpHeaders
        ).responseDecodable(of: AuthByCodeResponseModel.self) { response in
            switch response.result {
            case let .success(model):
                complation(.success(model))
            case let .failure(error):
                log.error(error)
                complation(.failure(error))
            }
        }
    }

    func refreshToken(refreshToken: String, completion: @escaping (Result<ASCOAuthCredential, Error>) -> Void) {
        accessToken(with: refreshToken) { result in
            switch result {
            case let .success(model):
                let credential = ASCOAuthCredential(
                    accessToken: model.access_token,
                    refreshToken: model.refresh_token,
                    expiration: Date().adding(.second, value: model.expires_in)
                )
                completion(.success(credential))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func getCurrentUser(credential: ASCOAuthCredential,
                        completion: @escaping (Result<OwncloudUserData, Error>) -> Void)
    {
        guard let currentUserURL = OwncloudHelper.makeURL(base: baseURL, addingPath: OwncloudEndpoints.Path.currentUser) else { return }
        var httpHeaders = HTTPHeaders(["Content-Type": "application/x-www-form-urlencoded"])
        httpHeaders.add(name: "Authorization", value: "Bearer \(credential.accessToken)")

        AF.request(
            currentUserURL,
            method: .get,
            headers: httpHeaders
        )
        .validate(statusCode: 200 ..< 300)
        .responseDecodable(of: OwncloudUserData.self, decoder: JSONDecoder()) { response in
            switch response.result {
            case let .success(user):
                DispatchQueue.main.async {
                    completion(.success(user))
                }

            case let .failure(error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

extension OwncloudApiClient {
    struct AuthByCodeResponseModel: Codable {
        var token_type: String
        var expires_in: Int
        var access_token: String
        var refresh_token: String
    }
}
