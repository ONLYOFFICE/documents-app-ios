//
//  NetworkingClient.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import ObjectMapper

typealias NetworkCompletionHandler = (_ result: Any?, _ error: Error?) -> Void
typealias NetworkProgressHandler = (_ result: Any?, _ progress: Double, _ error: Error?) -> Void

class ServerTrustPolicyManager: ServerTrustManager {
    override func serverTrustEvaluator(forHost host: String) throws -> ServerTrustEvaluating? {
        return DisabledTrustEvaluator()
    }
}

protocol NetworkingRequestingProtocol {
    func request<Response>(
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters?,
        _ completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)?
    )

    func request<Response>(
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters?,
        _ apply: ((_ data: MultipartFormData) -> Void)?,
        _ completion: ((_ result: Response?, _ progress: Double, _ error: NetworkingError?) -> Void)?
    )
}

class NetworkingClient: NSObject, NetworkingRequestingProtocol {
    // MARK: - Properties

    var baseURL: URL?
    var token: String? {
        didSet {
            if token != oldValue, let baseURLString = baseURL?.absoluteString {
                configure(url: baseURLString, token: token)
            }
        }
    }

    // MARK: - Internal Properties

    var manager = Alamofire.Session()
    private let queue = DispatchQueue(label: "asc.networking.client.\(String(describing: type(of: NetworkingClient.self)))")

    private lazy var configuration: URLSessionConfiguration = {
        $0.timeoutIntervalForRequest = 30
        $0.timeoutIntervalForResource = defaultTimeoutIntervalForResource
        return $0
    }(URLSessionConfiguration.default)

    var headers: HTTPHeaders = .default
    let defaultTimeoutIntervalForResource: TimeInterval = 30
    var sessions: [Alamofire.Session] = []

    // MARK: - init

    override init() {
        super.init()
    }

    func configure(url: String, token: String? = nil) {
        baseURL = URL(string: url)
        manager = Alamofire.Session(
            configuration: configuration,
            serverTrustManager: ServerTrustManager(allHostsMustBeEvaluated: false,
                                                   evaluators: [:])
        )
    }

    // MARK: - Control

    func clear() {
        cancelAll()
    }

    func cancelAll() {
        for manager in sessions + [manager] {
            manager.session.getAllTasks { tasks in
                tasks.forEach { $0.cancel() }
            }
        }
    }

    /// Compiler support method
    func request<Response>(
        endpoint: Endpoint<Response>,
        parameters: Parameters? = nil,
        completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)? = nil
    ) {
        request(endpoint, parameters, completion)
    }

    func request<Response>(
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters? = nil,
        _ completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)? = nil
    ) {
        guard let url = url(path: endpoint.path) else {
            completion?(nil, .invalidUrl)
            return
        }

        var params: Parameters = [:]
        var headers = headers

        if let endpointHeaders = endpoint.headers {
            headers = HTTPHeaders(headers.dictionary + endpointHeaders.dictionary)
        }

        if let keys = parameters?.keys {
            for key in keys {
                params[key] = parameters?[key]
            }
        }

        manager.request(
            url,
            method: endpoint.method,
            parameters: (params.count == 0) ? nil : params,
            encoding: endpoint.parameterEncoding ?? JSONEncoding.default,
            headers: headers
        )
        .validate()
        .responseData(queue: queue) { response in
            switch response.result {
            case let .success(value):
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
            case let .failure(error):
                let err = self.parseError(response.data, error)
                var result: Response?

                if let value = response.data {
                    do {
                        result = try endpoint.decode(value)
                    } catch {}
                }

                DispatchQueue.main.async {
                    completion?(result, err)
                }
            }
        }
    }

    func request<Response>(
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters? = nil,
        _ apply: ((_ data: MultipartFormData) -> Void)? = nil,
        _ completion: ((_ result: Response?, _ progress: Double, _ error: NetworkingError?) -> Void)? = nil
    ) {
        guard let url = url(path: endpoint.path) else {
            completion?(nil, 1, .invalidUrl)
            return
        }

        let params: Parameters = parameters ?? [:]
        var headers = headers

        if let endpointHeaders = endpoint.headers {
            headers = HTTPHeaders(headers.dictionary + endpointHeaders.dictionary)
        }

        let uploadManager = Alamofire.Session(
            configuration: {
                $0.timeoutIntervalForRequest = 600
                $0.timeoutIntervalForResource = 600
                return $0
            }(URLSessionConfiguration.default),
            interceptor: manager.interceptor,
            serverTrustManager: manager.serverTrustManager ?? ServerTrustManager(
                allHostsMustBeEvaluated: false,
                evaluators: [:]
            )
        )

        sessions.append(uploadManager)

        uploadManager.upload(multipartFormData: { data in
            for (key, value) in params {
                if let valueData = (value as? String)?.data(using: String.Encoding.utf8) {
                    data.append(valueData, withName: key)
                }
            }
            apply?(data)
        }, to: url,
        method: endpoint.method,
        headers: headers)
            .validate()
            .uploadProgress { progress in
                log.debug("Upload Progress: \(progress.fractionCompleted)")
                DispatchQueue.main.async {
                    completion?(nil, progress.fractionCompleted, nil)
                }
            }
            .responseData(queue: queue) { response in
                switch response.result {
                case let .success(value):
                    do {
                        let result = try endpoint.decode(value)
                        DispatchQueue.main.async {
                            completion?(result, 1, nil)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion?(nil, 1, .invalidData)
                        }
                    }
                case let .failure(error):
                    let err = self.parseError(response.data, error)
                    DispatchQueue.main.async {
                        completion?(nil, 1, err)
                    }
                }
                if let managerIndex = self.sessions.firstIndex(where: { $0 === uploadManager }) {
                    self.sessions.remove(at: managerIndex)
                }
            }
    }

    func download(
        _ path: String,
        _ to: URL,
        _ range: Range<Int64>? = nil,
        _ completion: ((_ result: Any?, _ progress: Double, _ error: NetworkingError?) -> Void)? = nil
    ) {
        guard let url = url(path: path) else {
            completion?(nil, 1, .invalidUrl)
            return
        }

        let destination: DownloadRequest.Destination = { _, _ in
            (to, [.removePreviousFile, .createIntermediateDirectories])
        }

        let downloadManager = Alamofire.Session(
            configuration: {
                $0.timeoutIntervalForRequest = 600
                $0.timeoutIntervalForResource = 600
                return $0
            }(URLSessionConfiguration.default),
            interceptor: manager.interceptor,
            serverTrustManager: manager.serverTrustManager ?? ServerTrustManager(
                allHostsMustBeEvaluated: false,
                evaluators: [:]
            )
        )

        sessions.append(downloadManager)

        var headers: HTTPHeaders = []

        if let range {
            headers.add(name: "Range", value: "bytes=\(range.lowerBound)-\(range.upperBound)")
        }

        downloadManager.download(
            url,
            headers: headers.isEmpty ? nil : headers,
            to: destination
        )
        .downloadProgress { progress in
            DispatchQueue.main.async {
                completion?(nil, progress.fractionCompleted, nil)
            }
        }
        .validate()
        .responseData { response in
            switch response.result {
            case let .success(data):
                DispatchQueue.main.async {
                    completion?(data, 1, nil)
                }
            case let .failure(error):
                let err = self.parseError(response.value, error)
                DispatchQueue.main.async {
                    completion?(nil, 1, err)
                }
            }
            if let managerIndex = self.sessions.firstIndex(where: { $0 === downloadManager }) {
                self.sessions.remove(at: managerIndex)
            }
        }
    }

    func parseError(_ data: Data?, _ error: AFError? = nil) -> NetworkingError {
        if let error {
            switch error {
            case let .sessionTaskFailed(error):
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        return .noInternet
                    case .cancelled:
                        return .cancelled
                    case .timedOut:
                        return .timeOut
                    default:
                        return .unknown(error: error)
                    }
                }

            case .sessionDeinitialized:
                return .sessionDeinitialized

            case .explicitlyCancelled:
                return .cancelled

            default:
                break
            }
        }

        return .invalidData
    }

    func url(path: String) -> URL? {
        return baseURL?.appendingPathComponent(path)
    }
}

extension NetworkingClient: URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        completionHandler(URLSession.AuthChallengeDisposition.useCredential,
                          URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

extension NetworkingClient {
    class func clearCookies(for url: URL?) {
        let cookieStorage = HTTPCookieStorage.shared

        if let url = url, let cookies = cookieStorage.cookies(for: url) {
            for cookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }
    }

//    class func request<Response>(
//        endpoint: Endpoint<Response>,
//        parameters: Parameters? = nil,
//        _ completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)? = nil) {
//
//        NetworkingClient.shared.request(endpoint, parameters, encoding, completion)
//    }
//
//    class func request<Response>(
//        endpoint: Endpoint<Response>,
//        parameters: Parameters? = nil,
//        apply: ((_ data: MultipartFormData) -> Void)? = nil,
//        _ completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)? = nil) {
//
//        NetworkingClient.shared.request(endpoint, parameters, apply, completion)
//    }
}
