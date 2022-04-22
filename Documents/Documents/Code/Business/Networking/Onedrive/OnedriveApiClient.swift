//
//  OnedriveApiClient.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

class OnedriveApiClient: NetworkingClient {
    
    public var credential: ASCOAuthCredential? {
        didSet {
            if oldValue == nil {
                configure(url: baseURL?.absoluteString ?? "", token: credential?.accessToken)
            }
        }
    }

    public var onRefreshToken: ((ASCOAuthCredential) -> Void)?

    override public init() {
        super.init()
        baseURL = URL(string: "https://graph.microsoft.com/v1.0/")
    }

    override public func configure(url: String, token: String? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30
        configuration.headers = .default

        let interceptor = OneDriveRequestInterceptor(api: self)

        manager = Session(
            configuration: configuration,
            interceptor: interceptor,
            serverTrustManager: ServerTrustPolicyManager(evaluators: [:])
        )
    }
}
