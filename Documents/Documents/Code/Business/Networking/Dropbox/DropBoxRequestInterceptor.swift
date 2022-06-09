//
//  DropBoxRequestInterceptor.swift
//  Documents
//
//  Created by Pavel Chernyshev on 21.04.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

class DropBoxRequestInterceptor: RequestInterceptor {
    enum DropBoxRequestInterceptorError: Error {
        case unauthtorized
    }

    private weak var api: DropboxApiClient?

    init(api: DropboxApiClient?) {
        self.api = api
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard let credential = api?.credential else {
            completion(.failure(DropBoxRequestInterceptorError.unauthtorized))
            return
        }

        var urlRequest = urlRequest
        urlRequest.headers.update(.authorization(bearerToken: credential.accessToken))
        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            /// The request did not fail due to a 401 Unauthorized response.
            /// Return the original error and don't retry the request.
            return completion(.doNotRetryWithError(error))
        }

        refreshToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .success(credential):
                self.api?.credential = credential
                self.api?.onRefreshToken?(credential)
                /// After updating the token we can safely retry the original request.
                completion(.retry)
            case let .failure(error):
                completion(.doNotRetryWithError(error))
            }
        }
    }

    private func refreshToken(completion: @escaping (Result<ASCOAuthCredential, Error>) -> Void) {
        guard let refreshToken = api?.credential?.refreshToken else {
            completion(.failure(DropBoxRequestInterceptorError.unauthtorized))
            return
        }

        let dropboxController = ASCConnectStorageOAuth2Dropbox()
        dropboxController.clientId = ASCConstants.Clouds.Dropbox.appId
        dropboxController.redirectUrl = ASCConstants.Clouds.Dropbox.redirectUri
        dropboxController.clientSecret = ASCConstants.Clouds.Dropbox.clientSecret

        dropboxController.accessToken(with: refreshToken) { result in
            switch result {
            case let .success(model):
                let credential = ASCOAuthCredential(
                    accessToken: model.accessToken,
                    refreshToken: refreshToken,
                    expiration: Date().adding(.second, value: model.expiresIn)
                )
                completion(.success(credential))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
