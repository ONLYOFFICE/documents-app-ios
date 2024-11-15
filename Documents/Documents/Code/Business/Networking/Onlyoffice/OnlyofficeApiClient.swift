//
//  OnlyofficeApiClient.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

class OnlyofficeTokenAdapter: RequestAdapter {
    private let accessToken: String
    private let client: OnlyofficeApiClient

    init(client: OnlyofficeApiClient, accessToken: String) {
        self.client = client
        self.accessToken = accessToken
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest

        if !accessToken.isEmpty {
            if client.isHttp2 {
                urlRequest.headers.update(.authorization(bearerToken: accessToken))
            } else {
                urlRequest.headers.update(.authorization(accessToken))
            }
        }
        completion(.success(urlRequest))
    }
}

class OnlyofficeApiClient: NetworkingClient {
    public static let shared = OnlyofficeApiClient()

    // MARK: - Properties

    public var expires: Date?
    public var serverVersion: OnlyofficeVersion?
    public var capabilities: OnlyofficeCapabilities?
    public var active: Bool {
        return baseURL != nil && token != nil
    }

    public var isHttp2: Bool {
        return serverVersion?.community?.isVersion(greaterThanOrEqualTo: "10.0") ?? false
    }

    private let queue = DispatchQueue(label: "asc.networking.client.\(String(describing: type(of: OnlyofficeApiClient.self)))")

    // MARK: - Lifecycle

    override public init() {
        super.init()
    }

    public init(apiClient: NetworkingClient) {
        super.init()
        super.configure(url: apiClient.baseURL?.absoluteString ?? "")
        headers = apiClient.headers
    }

    convenience init(url: String, token: String) {
        self.init()
        configure(url: url, token: token)
    }

    override public func configure(url: String? = nil, token: String? = nil) {
        baseURL = URL(string: url ?? "")

        // Initialize session manager
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = defaultTimeoutIntervalForResource
        configuration.headers = .default

        let adapter = OnlyofficeTokenAdapter(client: self, accessToken: token ?? "")

        manager = Session(
            configuration: configuration,
            interceptor: Interceptor(adapters: [adapter]),
            serverTrustManager: ServerTrustPolicyManager(evaluators: [:])
        )

        // Fetch server version
        fetchServerVersion(completion: nil)
    }

    override func parseError(_ data: Data?, _ error: AFError? = nil) -> NetworkingError {
        let networkingError = super.parseError(data, error)

        if let error {
            switch error {
            case let .responseValidationFailed(reason):
                switch reason {
                case let .unacceptableStatusCode(code):
                    switch code {
                    case 401:
                        return .apiError(error: OnlyofficeServerError.unauthorized)
                    case 402:
                        return .apiError(error: OnlyofficeServerError.paymentRequired)
                    case 413:
                        return .apiError(error: OnlyofficeServerError.requestTooLarge)
                    default:
                        break
                    }
                default:
                    break
                }
            default:
                break
            }
        }

        if let data {
            do {
                let json = try JSON(data: data)
                // TODO: extend custom error
                if let errorString = json["error"]["message"].string {
                    return .apiError(error: OnlyofficeServerError(rawValue: errorString))
                }
            } catch {
                log.debug(error)
            }
        }

        return networkingError
    }

    func reset() {
        baseURL = nil
        token = nil
        serverVersion = nil
        capabilities = nil
        configure()
    }

    func download(
        _ path: String,
        _ to: URL,
        _ range: Range<Int64>? = nil,
        _ processing: @escaping NetworkProgressHandler
    ) {
        guard let url = OnlyofficeApiClient.shared.absoluteUrl(from: URL(string: path)) else {
            processing(nil, 1, NetworkingError.invalidUrl)
            return
        }

        let destination: DownloadRequest.Destination = { _, _ in
            (to, [.removePreviousFile, .createIntermediateDirectories])
        }

        var headers: HTTPHeaders = []

        if baseURL?.host == url.host, let token, !token.isEmpty {
            headers.add(isHttp2 ? .authorization(bearerToken: token) : .authorization(token))
        }

        if let range {
            headers.add(name: "Range", value: "bytes=\(range.lowerBound)-\(range.upperBound)")
        }

        let redirectHandler = Redirector(
            behavior: Redirector.Behavior.modify { task, request, response in
                var redirectedRequest = request

                if let originalRequest = task.originalRequest,
                   let headers = originalRequest.allHTTPHeaderFields
                {
                    // Set Authorization in header if redirect to same host
                    if redirectedRequest.url?.host == url.host,
                       let authorizationHeaderValue = headers["Authorization"]
                    {
                        redirectedRequest.setValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
                    }

                    if let rangeHeaderValue = headers["Range"] {
                        redirectedRequest.setValue(rangeHeaderValue, forHTTPHeaderField: "Range")
                    }
                }

                return redirectedRequest
            }
        )

        let adapter = OnlyofficeTokenAdapter(client: self, accessToken: token ?? "")
        let downloadManager = Alamofire.Session(
            configuration: {
                $0.timeoutIntervalForRequest = 600
                $0.timeoutIntervalForResource = 600
                $0.headers = .default
                return $0
            }(URLSessionConfiguration.default),
            interceptor: Interceptor(adapters: [adapter]),
            serverTrustManager: ServerTrustManager(
                allHostsMustBeEvaluated: false,
                evaluators: [:]
            )
        )

        sessions.append(downloadManager)

        downloadManager.download(
            url,
            headers: headers.isEmpty ? nil : headers,
            to: destination
        )
        .downloadProgress(queue: queue) { progress in
            DispatchQueue.main.async {
                processing(nil, progress.fractionCompleted, nil)
            }
        }
        .redirect(using: redirectHandler)
        .validate()
        .responseData(queue: queue) { response in
            switch response.result {
            case let .success(data):
                DispatchQueue.main.async {
                    processing(data, 1, nil)
                }
            case let .failure(error):
                let err = self.parseError(response.value, error)
                DispatchQueue.main.async {
                    processing(nil, 1, err)
                }
            }

            if let managerIndex = self.sessions.firstIndex(where: { $0 === downloadManager }) {
                self.sessions.remove(at: managerIndex)
            }
        }
    }

    func upload<Response>(
        _ endpoint: Endpoint<Response>,
        _ data: Data,
        _ parameters: Parameters? = nil,
        _ mime: String? = nil,
        _ processing: @escaping ((_ result: Response?, _ progress: Double, _ error: NetworkingError?) -> Void)
    ) {
        guard let url = url(path: endpoint.path) else {
            processing(nil, 1, .invalidUrl)
            return
        }

//        ASCBaseApi.clearCookies(for: url)

        var headers: HTTPHeaders = [
            "Content-Length": String(data.count),
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
                let adapter = OnlyofficeTokenAdapter(client: self, accessToken: token ?? "")
                let uploadManager = Alamofire.Session(
                    configuration: {
                        $0.timeoutIntervalForRequest = 600
                        $0.timeoutIntervalForResource = 600
                        $0.headers = .default
                        return $0
                    }(URLSessionConfiguration.default),
                    interceptor: Interceptor(adapters: [adapter]),
                    serverTrustManager: ServerTrustManager(
                        allHostsMustBeEvaluated: false,
                        evaluators: [:]
                    )
                )

                sessions.append(uploadManager)

                uploadManager.upload(
                    data,
                    to: uploadUrl,
                    method: endpoint.method,
                    headers: headers
                )
                .uploadProgress(queue: queue) { progress in
                    log.debug("Upload Progress: \(progress.fractionCompleted)")
                    DispatchQueue.main.async {
                        processing(nil, progress.fractionCompleted, nil)
                    }
                }
                .validate(statusCode: 200 ..< 300)
                .responseData(queue: queue) { response in
                    switch response.result {
                    case let .success(value):
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
                    case let .failure(error):
                        let err = self.parseError(response.data, error)
                        DispatchQueue.main.async {
                            processing(nil, 1, err)
                        }
                    }

                    if let managerIndex = self.sessions.firstIndex(where: { $0 === uploadManager }) {
                        self.sessions.remove(at: managerIndex)
                    }
                }
            }
        }
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

    // MARK: - Private

    private func fetchServerVersion(completion: NetworkCompletionHandler?) {
        OnlyofficeApiClient.shared.request(OnlyofficeAPI.Endpoints.Settings.versions) { [weak self] response, error in
            defer { completion?(response?.result, error) }

            if let error = error {
                log.error(error)
                return
            }

            if let versions = response?.result {
                self?.serverVersion = versions
            }
        }
    }
}

extension OnlyofficeApiClient {
    class func request<Response>(
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters? = nil,
        _ completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)? = nil
    ) {
        NetworkingClient.clearCookies(for: OnlyofficeApiClient.shared.url(path: endpoint.path))
        OnlyofficeApiClient.shared.request(endpoint, parameters, completion)
    }

    class func request<Response>(
        _ endpoint: Endpoint<Response>,
        _ parameters: Parameters? = nil,
        _ apply: ((_ data: MultipartFormData) -> Void)? = nil,
        _ completion: ((_ result: Response?, _ progress: Double, _ error: NetworkingError?) -> Void)? = nil
    ) {
        NetworkingClient.clearCookies(for: OnlyofficeApiClient.shared.url(path: endpoint.path))
        OnlyofficeApiClient.shared.request(endpoint, parameters, apply, completion)
    }
}
