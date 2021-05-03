//
//  DropboxApiClient.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 30.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire

class DropboxTokenAdapter: RequestAdapter {
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

class DropboxApiClient: NetworkingClient {
    
    public override init() {
        super.init()
        baseURL = URL(string: "https://api.dropboxapi.com/2/")
    }
    
    override public func configure(url: String, token: String? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30
        configuration.headers = .default
        
        let adapter = DropboxTokenAdapter(accessToken: token ?? "")
        
        self.manager = Session(
            configuration: configuration,
            interceptor: Interceptor(adapters: [adapter]),
            serverTrustManager: ServerTrustPolicyManager(evaluators: [:])
        )
    }
}
