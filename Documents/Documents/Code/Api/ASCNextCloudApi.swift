//
//  ASCNextCloudApi.swift
//  Documents
//
//  Created by Alexander Yuzhin on 17/10/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire

extension ASCNextCloudApi {
    // Api paths
    static public let apiStorageStats = "index.php/apps/files/ajax/getstoragestats.php"
}

class ASCNextCloudTokenAdapter: RequestAdapter {
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

class ASCNextCloudApi: ASCBaseApi {
    public var baseUrl: String?
    public var user: String? {
        didSet {
            initManager()
        }
    }
    public var password: String? {
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
        guard let user = user, let password = password else {
            manager = Session()
            return
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30
        configuration.headers = .default
        
        let adapter = ASCNextCloudTokenAdapter(user: user, password: password)
        
        manager = Session(
            configuration: configuration,
            interceptor: Interceptor(adapters: [adapter]),
            serverTrustManager: ASCServerTrustPolicyManager(evaluators: [:])
        )
    }

    func get(_ path: String,
             parameters: Parameters? = nil,
             encoding: ParameterEncoding = URLEncoding.default,
             completion: @escaping ASCApiCompletionHandler) {
        guard let baseUrl = baseUrl else {
            log.error("\(String(describing: self)) no baseUrl")
            completion(nil, nil, nil)
            return
        }

        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            log.error("Encoding path")
            completion(nil, nil, nil)
            return
        }

        let url = "\(baseUrl)/\(encodePath)"

        ASCBaseApi.clearCookies(for: URL(string: baseUrl))

        manager
            .request(url, method: .get, parameters: parameters, encoding: encoding, headers: nil)
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

    private func errorInfo(by response: Any) -> [String: Any]? {
        if let response = response as? AFDataResponse<Any> {
            if let data = response.data {
                do {
                    return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                } catch {
                    log.error(error)
                }
            }
        }

        return nil
    }

    func errorMessage(by response: Any) -> String {
        if let errorInfo = errorInfo(by: response) {
            if let error = errorInfo["error"] as? [String: Any], let message = error["message"] as? String {
                return message
            }
        }

        return String.localizedStringWithFormat("The %@ server is not available.", baseUrl ?? "")
    }

    func absoluteUrl(from url: URL?) -> URL? {
        if let url = url {
            if let _ = url.host {
                return url
            } else {
                return URL(string: (baseUrl ?? "") + url.absoluteString)
            }
        }
        return nil
    }
}
