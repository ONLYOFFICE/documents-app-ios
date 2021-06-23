//
//  OnedriveApiClient.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire

class OnedriveTokenAdapter: RequestAdapter {
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

class OnedriveApiClient: NetworkingClient {
    
    public override init() {
        super.init()
        baseURL = URL(string: "https://graph.microsoft.com/v1.0/")
    }

    override public func configure(url: String, token: String? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30
        configuration.headers = .default
        
        let adapter = OnedriveTokenAdapter(accessToken: token ?? "")
        
        self.manager = Session(
            configuration: configuration,
            interceptor: Interceptor(adapters: [adapter]),
            serverTrustManager: ServerTrustPolicyManager(evaluators: [:])
        )
    }
}
