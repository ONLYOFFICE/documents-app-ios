//
//  ASCDropboxApi.swift
//  Documents
//
//  Created by Alexander Yuzhin on 21.10.2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire

extension ASCDropboxApi {
    static public let apiBaseUrl = "https://api.dropboxapi.com/2/"
    
    // Api paths
    static public let apiCurrentAccount = "users/get_current_account"
    static public let apiTemporaryLink = "files/get_temporary_link"
}

class ASCDropboxTokenAdapter: RequestAdapter {
    private let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.headers.update(.authorization(bearerToken: accessToken))
        completion(.success(urlRequest))
    }
}

class ASCDropboxApi: ASCBaseApi {
    public let baseUrl: String = apiBaseUrl
    
    public var token: String? = nil {
        didSet {
            initManager()
        }
    }
    
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
        
        let adapter = ASCDropboxTokenAdapter(accessToken: token ?? "")
        
        manager = Session(
            configuration: configuration,
            interceptor: Interceptor(adapters: [adapter]),
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

    func cancelAllTasks() {
        manager.session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }
}
