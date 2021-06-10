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
            if token != oldValue {
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
    
    private let queue = DispatchQueue(label: "asc.networking.client.\(String(describing: type(of: self)))")
    
    // MARK: - Lifecycle
    
    public override init() {
        super.init()
//        configure()
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
    
    func download(
        _ path: String,
        _ to: URL,
        _ processing: @escaping NetworkProgressHandler) {
        
        guard let url = self.url(path: path) else {
            processing(nil, 1, .invalidUrl)
            return
        }
        
        let destination: DownloadRequest.Destination = { _, _ in
            return (to, [.removePreviousFile, .createIntermediateDirectories])
        }

        var headers: HTTPHeaders?
        
        if baseURL?.host == url.host, let token = token {
            headers = [
                "Authorization": isHttp2 ? "Bearer \(token)" : token
            ]
        }
        
        self.manager.download(
            url,
            headers: headers,
            to: destination
        )
        .downloadProgress(queue: self.queue) { progress in
            log.debug("Download Progress: \(progress.fractionCompleted)")
            DispatchQueue.main.async(execute: {
                processing(nil, progress.fractionCompleted, nil)
            })
        }
        .responseData(queue: self.queue) { response in
            switch response.result {
            case .success(let data):
                DispatchQueue.main.async {
                    processing(data, 1, nil)
                }
            case .failure(let error):
                let err = self.parseError(response.value, error)
                DispatchQueue.main.async {
                    processing(nil, 1, err)
                }
            }
        }
    }
    
    func upload<Response>(
        _ endpoint: Endpoint<Response>,
        _ data: Data,
        _ parameters: Parameters? = nil,
        _ mime: String? = nil,
        _ processing: @escaping ((_ result: Response?, _ progress: Double, _ error: NetworkingError?) -> Void)) {
        
        guard let url = self.url(path: endpoint.path) else {
            processing(nil, 1, .invalidUrl)
            return
        }

//        ASCBaseApi.clearCookies(for: url)

        var headers: HTTPHeaders = [
            "Content-Length": String(data.count)
        ]

        if let mime = mime {
            headers["Content-Type"] = mime
        }
        
        let excludeParamKeys = ["mime"]
        
        if var urlComponents = URLComponents(string: url.absoluteString) {
            var queryItems = urlComponents.queryItems ?? []
            for (key, value) in parameters ?? [:] {
                if excludeParamKeys.contains(key) { continue }
                if let stringValue = value as? String {
                    queryItems.append(URLQueryItem(name: key, value: stringValue))
                }
            }
            urlComponents.queryItems = queryItems
            
            if let uploadUrl = urlComponents.url {
                
                self.manager.upload(
                    data,
                    to: uploadUrl,
                    method: endpoint.method,
                    headers: headers)
                    .uploadProgress(queue: self.queue) { progress in
                        log.debug("Upload Progress: \(progress.fractionCompleted)")
                        DispatchQueue.main.async {
                            processing(nil, progress.fractionCompleted, nil)
                        }
                    }
                    .validate(statusCode: 200..<300)
                    .responseData(queue: self.queue) { response in
                        switch response.result {
                        case .success(let value):
                            do {
                                let result = try endpoint.decode(value)
                                DispatchQueue.main.async {
                                    processing(result, 1, nil)
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    processing(nil, 1, .invalidData)
                                }
                            }
                        case .failure(let error):
                            let err = self.parseError(response.data, error)
                            DispatchQueue.main.async {
                                processing(nil, 1, err)
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Private
    
    private func fetchServerVersion(completion: NetworkCompletionHandler?) {
        OnlyofficeApiClient.shared.request(OnlyofficeAPI.Endpoints.serversVersion) { [weak self] response, error in
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
        
        NetworkingClient.clearCookies(for: OnlyofficeApiClient.shared.url(path: endpoint.path))
        OnlyofficeApiClient.shared.request(endpoint, parameters, completion)
    }
    
    class func request<Response>(
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters? = nil,
        _ apply: ((_ data: MultipartFormData) -> Void)? = nil,
        _ completion: ((_ result: Response?, _ progress: Double, _ error: NetworkingError?) -> Void)? = nil) {
        
        NetworkingClient.clearCookies(for: OnlyofficeApiClient.shared.url(path: endpoint.path))
        OnlyofficeApiClient.shared.request(endpoint, parameters, apply, completion)
    }
}
