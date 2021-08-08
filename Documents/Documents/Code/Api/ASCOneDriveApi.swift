//
//  ASCOneDriveApi.swift
//  Documents
//
//  Created by Павел Чернышев on 28.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire

extension ASCOneDriveApi {
    static private let version = "v1.0"
    
    static public let apiBaseUrl = "https://graph.microsoft.com/\(version)/me"
    
    // Api paths
    static public let apiCurrentAccount = "users"
    static public let apiTemporaryLink = "drive"
}

struct ASCOneDriveOAuthCredential: AuthenticationCredential {
    let accessToken: String
    let refreshToken: String
    let expiration: Date

    var requiresRefresh: Bool {
        return expiration < Date()
    }
}

class ASCOneDriveRequestInterceptor: RequestInterceptor {
    enum ASCOneDriveRequestInterceptorError: Error {
        case unauthtorized
    }

    private weak var api: ASCOneDriveApi?
    
    init(api: ASCOneDriveApi?) {
        self.api = api
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard let credential = api?.credential else {
            completion(.failure(ASCOneDriveRequestInterceptorError.unauthtorized));
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
            case .success(let credential):
                self.api?.credential = credential
                self.api?.onRefreshToken?(credential)
                /// After updating the token we can safely retry the original request.
                completion(.retry)
            case .failure(let error):
                completion(.doNotRetryWithError(error))
            }
        }
    }
    
    private func refreshToken(completion: @escaping (Result<ASCOneDriveOAuthCredential, Error>) -> Void) {
        guard let refreshToken = api?.credential?.refreshToken else {
            completion(.failure(ASCOneDriveRequestInterceptorError.unauthtorized))
            return
        }
        
        let onedriveController = ASCConnectStorageOAuth2OneDrive()
        onedriveController.clientId = ASCConstants.Clouds.OneDrive.clientId
        onedriveController.redirectUrl = ASCConstants.Clouds.OneDrive.redirectUri
        onedriveController.clientSecret = ASCConstants.Clouds.OneDrive.clientSecret
        
        onedriveController.accessToken(with: refreshToken) { result in
            switch result {
            case .success(let model):
                let credential = ASCOneDriveOAuthCredential(
                    accessToken: model.access_token,
                    refreshToken: model.refresh_token,
                    expiration: Date().adding(.second, value: model.expires_in)
                )
                completion(.success(credential))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

class ASCOneDriveApi: ASCBaseApi {
    public let baseUrl: String = apiBaseUrl
    
    public var credential: ASCOneDriveOAuthCredential? {
        didSet {
            initManager()
        }
    }
    
    public var onRefreshToken: ((ASCOneDriveOAuthCredential) -> Void)?
    
    private var manager: Alamofire.Session = Session()
    
    override init () {
        super.init()
        self.initManager()
    }
    
    private func initManager() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30
        configuration.headers = .default
        
        let interceptor = ASCOneDriveRequestInterceptor(api: self)
        
        manager = Session(
            configuration: configuration,
            interceptor: interceptor,
            serverTrustManager: ASCServerTrustPolicyManager(evaluators: [:])
        )
    }

    func post(_ path: String,
              parameters: Parameters? = nil,
              encoding: ParameterEncoding = URLEncoding.default,
              completion: @escaping ASCApiCompletionHandler)
    {
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            log.error("Encoding path")
            completion(nil, nil, nil)
            return
        }

        let url = "\(baseUrl)\(encodePath)"

        ASCBaseApi.clearCookies(for: URL(string: baseUrl))

        manager
            .request(url, method: .post, parameters: parameters, encoding: encoding)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            completion(responseJson, nil, response)
                            return
                        }

                        completion(nil, nil, response)
                    case .failure(let error):
                        completion(nil, error, response)
                        log.error(response)
                    }
                })
        }
    }
    
    func get(_ path: String,
                           parameters: Parameters? = nil,
                           encoding: ParameterEncoding = URLEncoding.default,
                           completion: @escaping ASCApiCompletionHandler) {
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            log.error("Encoding path")
            completion(nil, nil, nil)
            return
        }

        let url = "\(baseUrl)\(encodePath)"
        
        ASCBaseApi.clearCookies(for: URL(string: baseUrl))

        manager
            .request(url, method: .get, parameters: parameters, encoding: encoding)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            completion(responseJson, nil, response)
                            return
                        }

                        completion(nil, nil, response)
                    case .failure(let error):
                        completion(nil, error, response)
                        log.error(response)
                    }
                })
        }
    }

    func cancelAllTasks() {
        manager.session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }
}
