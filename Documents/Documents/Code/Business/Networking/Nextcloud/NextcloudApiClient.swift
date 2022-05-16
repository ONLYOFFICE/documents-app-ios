//
//  NextcloudApiClient.swift
//  Documents
//
//  Created by Alexander Yuzhin on 30.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

class NextcloudTokenAdapter: RequestAdapter {
    private let user: String
    private let password: String

    init(user: String, password: String) {
        self.user = user
        self.password = password
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.headers.update(.authorization(username: user, password: password))
        completion(.success(urlRequest))
    }
}

class NextcloudApiClient: NetworkingClient {
    override public init() {
        super.init()
    }

    convenience init(url: String, user: String, password: String) {
        self.init()
        configure(url: url, user: user, password: password)
    }

    public func configure(url: String, user: String? = nil, password: String? = nil) {
        guard let user = user, let password = password else {
            manager = Session()
            return
        }

        baseURL = URL(string: url)

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.headers = .default

        let adapter = NextcloudTokenAdapter(user: user, password: password)

        manager = Session(
            configuration: configuration,
            interceptor: Interceptor(adapters: [adapter]),
            serverTrustManager: ServerTrustPolicyManager(evaluators: [:])
        )
    }

    override func parseError(_ data: Data?, _ error: AFError? = nil) -> NetworkingError {
        let error = super.parseError(data, error)

        if let data = data {
            do {
                let json = try JSON(data: data)
                if let errorString = json["message"].string {
                    return .apiError(error: NextcloudServerError(rawValue: errorString))
                }
            } catch {
                log.debug(error)
            }
        }

        return error
    }

    func absoluteUrl(from url: URL?) -> URL? {
        if let url = url {
            if let _ = url.host {
                return url
            } else {
                return URL(string: (baseURL?.absoluteString ?? "") + url.absoluteString)
            }
        }
        return nil
    }
}
