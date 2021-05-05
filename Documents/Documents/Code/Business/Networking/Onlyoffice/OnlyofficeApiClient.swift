//
//  OnlyofficeApiClient.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class OnlyofficeTokenAdapter: RequestAdapter {
    private let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        
        if ASCOnlyOfficeApi.shared.isHttp2 {
            urlRequest.headers.update(.authorization(bearerToken: accessToken))
        } else {
            urlRequest.headers.update(.authorization(accessToken)) // Legacy portals
        }
        completion(.success(urlRequest))
    }
}


class OnlyofficeApiClient: NetworkingClient {
    
    public static let shared = OnlyofficeApiClient()
    
    // MARK: - Properties
    
    override public var token: String? {
        didSet {
            if let baseURLString = baseURL?.absoluteString {
                configure(url: baseURLString, token: token)
                fetchServerVersion(completion: nil)
            }
        }
    }
    public var expires: Date?
    public var serverVersion: String?
    public var capabilities: OnlyofficeCapabilities?
    public var active: Bool {
        return baseURL != nil && token != nil
    }
    public var isHttp2: Bool {
        return serverVersion?.isVersion(greaterThanOrEqualTo: "10.0") ?? false
    }
    
    // MARK: - Lifecycle
    
    public override init() {
        super.init()
        configure()
    }
    
    convenience init(url: String, token: String) {
        self.init()
        configure(url: url, token: token)
        fetchServerVersion(completion: nil)
    }
    
    override public func configure(url: String? = nil, token: String? = nil) {
        if let url = url {
            baseURL = URL(string: url)
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30
        configuration.headers = .default
        
        let adapter = OnlyofficeTokenAdapter(accessToken: token ?? "")
        
        self.manager = Session(
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
                // TODO: extend custom error
                if let errorString = json["error"]["message"].string {
                    return .apiError(error: OnlyofficeServerError(rawValue: errorString))
                }
            } catch (let error) {
                log.debug(error)
            }
        }
        
        return error
    }
    
    class func reset() {
        OnlyofficeApiClient.shared.baseURL = nil
        OnlyofficeApiClient.shared.token = nil
        OnlyofficeApiClient.shared.serverVersion = nil
        OnlyofficeApiClient.shared.capabilities = nil
    }
    
    // MARK: - Private
    
    private func fetchServerVersion(completion: NetworkCompletionHandler?) {
        request(OnlyofficeAPI.Endpoints.serversVersion) { [weak self] response, error in
            defer { completion?(response?.result, error) }
            
            if let error = error {
                log.error(error)
                return
            }
            
            if let versions = response?.result {
                self?.serverVersion = versions.community
            }
        }
    }
    
}


extension OnlyofficeApiClient {
    
    class func request<Response>(
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters? = nil,
        _ completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)? = nil) {
        
        OnlyofficeApiClient.shared.request(endpoint, parameters, completion)
    }
    
    class func request<Response>(
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters? = nil,
        _ apply: ((_ data: MultipartFormData) -> Void)? = nil,
        _ completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)? = nil) {
        
        OnlyofficeApiClient.shared.request(endpoint, parameters, apply, completion)
    }
}
