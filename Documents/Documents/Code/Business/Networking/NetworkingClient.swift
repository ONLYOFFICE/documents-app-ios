//
//  NetworkingClient.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 29.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import ObjectMapper

class NetworkingService: NSObject {
    
    // MARK: - Properties
    
    public var baseURL: URL?
    public var token: String?
    
    // MARK: - Internal Properties
    
    private var manager = Alamofire.Session()
    private let queue = DispatchQueue(label: "asc.networking.client.\(String(describing: type(of: self)))")
    
    private lazy var configuration: URLSessionConfiguration = {
        $0.timeoutIntervalForRequest = 60 * 3
        $0.timeoutIntervalForResource = 60 * 3
        return $0
    } (URLSessionConfiguration.default)
    
    public var headers: HTTPHeaders = .default
    
    // MARK: - init
    
    public override init() {
        super.init()
    }
    
    public func configure(url: String) {
        self.baseURL = URL(string: url)
        self.manager = Alamofire.Session(
            configuration: self.configuration,
            serverTrustManager: ServerTrustManager(allHostsMustBeEvaluated: false,
                                                   evaluators: [:]))
    }
    
    // MARK: - Control
    
    public func clear() {
        cancelAll()
    }
    
    public func cancelAll() {
        self.manager.session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }
    
    func request<Response> (
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters? = nil,
        _ completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)? = nil) {
        
        guard let url = self.url(path: endpoint.path) else {
            completion?(nil, .invalidUrl)
            return
        }
        
        var params: Parameters = [:]
        
        if let keys = parameters?.keys {
            for key in keys {
                params[key] = parameters?[key]
            }
        }
        
        self.manager.request(
            url,
            method: endpoint.method,
            parameters: (params.count == 0) ? nil : params,
            encoding: JSONEncoding.default,
            headers: self.headers)
            .validate()
            .responseData(queue: self.queue) { response in
                
                switch response.result {
                case .success(let value):
                    do {
                        let result = try endpoint.decode(value)
                        DispatchQueue.main.async {
                            completion?(result, nil)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion?(nil, .invalidData)
                        }
                    }
                    break
                case .failure(let error):
                    let err = self.parseError(response.data, error)
                    DispatchQueue.main.async {
                        completion?(nil, err)
                    }
                    break
                }
            }
    }
    
    func request<Response> (
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters? = nil,
        _ apply: ((_ data: MultipartFormData) -> Void)? = nil,
        _ completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)? = nil) {
        
        guard let url = self.url(path: endpoint.path) else {
            completion?(nil, .invalidUrl)
            return
        }
        
        let params: Parameters = [:]
        
        self.manager.upload(multipartFormData: { data in
            for (key, value) in params {
                if let valueData = (value as? String)?.data(using: String.Encoding.utf8) {
                    data.append(valueData, withName: key)
                }
            }
            apply?(data)
        }, to: url,
        method: endpoint.method,
        headers: self.headers)
        .responseData(queue: self.queue) { response in
            switch response.result {
            case .success(let value):
                do {
                    let result = try endpoint.decode(value)
                    DispatchQueue.main.async {
                        completion?(result, nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion?(nil, .invalidData)
                    }
                }
                break
            case .failure(let error):
                let err = self.parseError(response.data, error)
                DispatchQueue.main.async {
                    completion?(nil, err)
                }
                break
            }
        }
    }
    
    func parseError(_ data: Data?, _ error: AFError? = nil) -> NetworkingError {
        // TODO: check errors

        if let error = error {
            if case .sessionTaskFailed(let sessionError) = error, let urlError = sessionError as? URLError {
                if urlError.code  == URLError.Code.notConnectedToInternet {
                    return .noInternet
                }
            }
        }
        
        return .invalidData
    }
    
    func url(path: String) -> URL? {
        return baseURL?.appendingPathComponent(path)
    }
}

extension NetworkingService: URLSessionDelegate {
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(URLSession.AuthChallengeDisposition.useCredential,
                          URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
