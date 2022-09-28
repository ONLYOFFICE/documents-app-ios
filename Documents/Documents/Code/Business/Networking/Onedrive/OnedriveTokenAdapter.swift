//
//  OnedriveTokenAdapter.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

class OneDriveRequestInterceptor: RequestInterceptor {
    enum OneDriveRequestInterceptorError: Error {
        case unauthtorized
    }

    private weak var api: OnedriveApiClient?

    init(api: OnedriveApiClient?) {
        self.api = api
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard let credential = api?.credential else {
            completion(.failure(OneDriveRequestInterceptorError.unauthtorized))
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
            completion(.failure(OneDriveRequestInterceptorError.unauthtorized))
            return
        }

        let onedriveController = ASCConnectStorageOAuth2OneDrive()
        onedriveController.clientId = ASCConstants.Clouds.OneDrive.clientId
        onedriveController.redirectUrl = ASCConstants.Clouds.OneDrive.redirectUri
        onedriveController.clientSecret = ASCConstants.Clouds.OneDrive.clientSecret

        onedriveController.accessToken(with: refreshToken) { result in
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
}
