//
//  ASCOnlyOfficeApi.swift
//  Documents-Swift
//
//  Created by Alexander Yuzhin on 3/3/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import Alamofire
import Kingfisher

extension ASCOnlyOfficeApi {
    // Api version
    static private let version = "2.0"
    
    // Api paths
    static public let apiAuthentication         = "api/\(version)/authentication"
    static public let apiAuthenticationPhone    = "api/\(version)/authentication/setphone"
    static public let apiAuthenticationCode     = "api/\(version)/authentication/sendsms"
    static public let apiCapabilities           = "api/\(version)/capabilities"
    static public let apiDeviceRegistration     = "api/\(version)/portal/mobile/registration"
    static public let apiPeopleSelf             = "api/\(version)/people/@self"
    static public let apiPeoplePhoto            = "api/\(version)/people/%@/photo"
    static public let apiDocumentService        = "api/\(version)/files/docservice"
    static public let apiServersVersion         = "api/\(version)/settings/version/build"
    static public let apiFilesPath              = "api/\(version)/files/"
    static public let apiFolderMy               = "@my"
    static public let apiFolderShare            = "@share"
    static public let apiFolderCommon           = "@common"
    static public let apiFolderProjects         = "@projects"
    static public let apiFolderTrash            = "@trash"
    static public let apiOpenEditFile           = "api/\(version)/files/file/%@/openedit"
    static public let apiCreateFile             = "api/\(version)/files/%@/file"
    static public let apiCreateFolder           = "api/\(version)/files/folder/%@"
    static public let apiInsertFile             = "api/\(version)/files/%@/insert"
    static public let apiFileId                 = "api/\(version)/files/file/%@"
    static public let apiFolderId               = "api/\(version)/files/folder/%@"
    static public let apiFileOperations         = "api/\(version)/files/fileops"
    static public let apiBatchCopy              = "api/\(version)/files/fileops/copy"
    static public let apiBatchMove              = "api/\(version)/files/fileops/move"
    static public let apiBatchDelete            = "api/\(version)/files/fileops/delete"
    static public let apiEmptyTrash             = "api/\(version)/files/fileops/emptytrash"
    static public let apiBatchShare             = "api/\(version)/files/share"
    static public let apiSettingStoreOriginal   = "api/\(version)/files/storeoriginal"
    static public let apiFileCheckConversion    = "api/\(version)/files/file/%@/checkconversion"
    static public let apiThirdParty             = "api/\(version)/files/thirdparty"
    static public let apiThirdPartyCapabilities = "api/\(version)/files/thirdparty/capabilities"
    static public let apiShareFile              = "api/\(version)/files/file/%@/share"
    static public let apiShareFolder            = "api/\(version)/files/folder/%@/share"
    static public let apiFileStartEdit          = "api/\(version)/files/file/%@/startedit"
    static public let apiFileTrackEdit          = "api/\(version)/files/file/%@/trackeditfile"
    static public let apiSaveEditing            = "api/\(version)/files/file/%@/saveediting"
    static public let apiFilesFavorite          = "api/\(version)/files/favorites"
    static public let apiUsers                  = "api/\(version)/people"
    static public let apiGroups                 = "api/\(version)/group"
    static public let apiForgotPassword         = "api/\(version)/people/password"
}

enum ASCOnlyOfficeError: String {
    case paymentRequired = "PaymentRequired"
    case forbidden = "Forbidden"
    case notFound = "NotFound"
    case unknown = "Unknown"
    
    init(rawValue: String) {
        switch rawValue {
        case "PaymentRequired":
            self = .paymentRequired
        case "Forbidden":
            self = .forbidden
        case "NotFound":
            self = .notFound
        default:
            self = .unknown
        }
    }
    
    var localized: String {
        switch self {
        case .paymentRequired:
            return ASCLocalization.Error.paymentRequiredTitle
        case .forbidden:
            return ASCLocalization.Error.forbiddenTitle
        case .notFound:
            return ASCLocalization.Error.notFoundTitle
        default:
            return ASCLocalization.Error.unknownTitle
        }
    }
}

class ASCAccessTokenAdapter: RequestAdapter {
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

class ASCOnlyOfficeApi: ASCBaseApi {
    public static let shared = ASCOnlyOfficeApi()

    public var baseUrl: String? = nil {
        didSet { }
    }
    public var token: String? = nil {
        didSet {
            if token != oldValue {
                initManager()
                
                if let baseUrl = baseUrl {
                    fetchServerVersion(baseUrl, completion: nil)
                }
            }
        }
    }

    public var active: Bool {
        get {
            return baseUrl != nil && token != nil
        }
    }
    public var expires: Date?
    public var serverVersion: String?
    public var capabilities: ASCPortalCapabilities?
    public var isHttp2: Bool {
        get {
            if let communityServerVersion = ASCOnlyOfficeApi.shared.serverVersion {
                return communityServerVersion.isVersion(greaterThanOrEqualTo: "10.0")
            }
            return false
        }
    }

    private var manager: Alamofire.Session = Session()
    private var additionalManagers: [UUID : Alamofire.Session] = [:]

    override init () {
        super.init()
        self.initManager()

        localizeError()
    }
    
    private func initManager() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30
        configuration.headers = .default
        
        let adapter = ASCAccessTokenAdapter(accessToken: token ?? "")
        
        manager = Session(
            configuration: configuration,
            interceptor: Interceptor(adapters: [adapter]),
            serverTrustManager: ASCServerTrustPolicyManager(evaluators: [:])
        )
    }

    private func localizeError() {
        _ = NSLocalizedString("User authentication failed", comment: "Error message")
        _ = NSLocalizedString("Invalid URL: The format ot the URL could not be determined", comment: "Error message")
    }

    public func fetchServerVersion(_ path: String, completion: ASCApiCompletionHandler?) {
        let url = "\(path)/\(ASCOnlyOfficeApi.apiServersVersion).json"
        ASCOnlyOfficeApi.shared.manager
            .request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let result = responseJson["response"] as? [String: Any] {
                                if let communityServer = result["communityServer"] as? String {
                                    ASCOnlyOfficeApi.shared.serverVersion = communityServer
                                    completion?(result, nil, response)
                                }
                                return
                            }
                        }
                        completion?(nil, nil, response)
                    case .failure(let error):
                        completion?(nil, error, response)
                        log.error(response)
                    }
                })
        }
    }

    static public func reset() {
        ASCOnlyOfficeApi.shared.baseUrl = nil
        ASCOnlyOfficeApi.shared.token = nil
        ASCOnlyOfficeApi.shared.serverVersion = nil
        ASCOnlyOfficeApi.shared.capabilities = nil
    }

    static public func get(_ path: String,
                           parameters: Parameters? = nil,
                           encoding: ParameterEncoding = URLEncoding.default,
                           completion: @escaping ASCApiCompletionHandler) {
        guard let baseUrl = ASCOnlyOfficeApi.shared.baseUrl else {
            log.error("ASCApi no baseUrl")
            completion(nil, nil, nil)
            return
        }
        
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            log.error("Encoding path")
            completion(nil, nil, nil)
            return
        }

        let url = "\(baseUrl)/\(encodePath).json"

        clearCookies(for: URL(string: url))

        ASCOnlyOfficeApi.shared.manager
            .request(url, method: .get, parameters: parameters, encoding: encoding, headers: nil)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let result = responseJson["response"] {
                                completion(result, nil, response)
                                return
                            }
                        }

                        completion(nil, nil, response)
                    case .failure(let error):
                        completion(nil, error, response)
                        log.error(response)
                    }
                })
        }
    }
    
    static public func post(_ path: String,
                            parameters: Parameters? = nil,
                            encoding: ParameterEncoding = URLEncoding.default,
                            completion: @escaping ASCApiCompletionHandler) {
        guard let baseUrl = ASCOnlyOfficeApi.shared.baseUrl else {
            log.error("ASCApi no baseUrl")
            completion(nil, nil, nil)
            return
        }
        
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            log.error("Encoding path")
            completion(nil, nil, nil)
            return
        }
        
        let url = "\(baseUrl)/\(encodePath).json"

        clearCookies(for: URL(string: url))

        ASCOnlyOfficeApi.shared.manager
            .request(url, method: .post, parameters: parameters, encoding: encoding, headers: nil)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let result = responseJson["response"] {
                                completion(result, nil, response)
                                return
                            }
                        }
                        
                        completion(nil, nil, response)
                    case .failure(let error):
                        completion(nil, error, response)
                        log.error(response)
                    }
                })
        }
    }
    
    static public func put(_ path: String,
                           parameters: Parameters? = nil,
                           encoding: ParameterEncoding = URLEncoding.default,
                           completion: @escaping ASCApiCompletionHandler) {
        guard let baseUrl = ASCOnlyOfficeApi.shared.baseUrl else {
            log.error("ASCApi no baseUrl")
            completion(nil, nil, nil)
            return
        }
        
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            log.error("Encoding path")
            completion(nil, nil, nil)
            return
        }
        
        let url = "\(baseUrl)/\(encodePath).json"

        clearCookies(for: URL(string: url))

        ASCOnlyOfficeApi.shared.manager
            .request(url, method: .put, parameters: parameters, encoding: encoding, headers: nil)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let result = responseJson["response"] {
                                completion(result, nil, response)
                                return
                            }
                        }
                        
                        completion(nil, nil, response)
                    case .failure(let error):
                        completion(nil, error, response)
                        log.error(response)
                    }
                })
        }
    }
    
    static public func delete(_ path: String,
                              parameters: Parameters? = nil,
                              encoding: ParameterEncoding = URLEncoding.default,
                              completion: @escaping ASCApiCompletionHandler) {
        guard let baseUrl = ASCOnlyOfficeApi.shared.baseUrl else {
            log.error("ASCApi no baseUrl")
            completion(nil, nil, nil)
            return
        }
        
        guard let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            log.error("Encoding path")
            completion(nil, nil, nil)
            return
        }
        
        let url = "\(baseUrl)/\(encodePath).json"

        clearCookies(for: URL(string: url))

        ASCOnlyOfficeApi.shared.manager
            .request(url, method: .delete, parameters: parameters, encoding: encoding, headers: nil)
            .validate()
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let result = responseJson["response"] {
                                completion(result, nil, response)
                                return
                            }
                        }
                        
                        completion(nil, nil, response)
                    case .failure(let error):
                        completion(nil, error, response)
                        log.error(response)
                    }
                })
        }
    }
    
    func download(_ path: String, to: URL, processing: @escaping ASCApiProgressHandler) {
        guard let _ = ASCOnlyOfficeApi.shared.baseUrl else {
            log.error("ASCApi no baseUrl")
            processing(0, nil, nil, nil)
            return
        }
        
        if let portalUrl = ASCOnlyOfficeApi.absoluteUrl(from: URL(string: path)) {
            let destination: DownloadRequest.Destination = { url, respons in
                return (to, [.removePreviousFile, .createIntermediateDirectories])
            }

            var httpHeaders: HTTPHeaders? = nil

            // TODO: Hotfix by Linnic. Remove after resolve of conflict between SAAS and Enterprise versions
            if let baseUrl = ASCOnlyOfficeApi.shared.baseUrl, URL(string: baseUrl)?.host == portalUrl.host {
                let token = ASCOnlyOfficeApi.shared.token ?? ""
                httpHeaders = [
                    "Authorization": isHttp2 ? "Bearer \(token)" : token
                ]
            }

            let downloadManager = ASCOnlyOfficeApi.createInternalSessionManager(timeoutInterval: 36000)

            let uuid = UUID()
            additionalManagers[uuid] = downloadManager
            
            downloadManager.download(
                portalUrl,
                method: .get,
                parameters: nil,
                encoding: URLEncoding.default,
                headers: httpHeaders,
                to: destination
                )
                .validate()
                .downloadProgress { progress in
                    log.debug(progress.fractionCompleted)
                    DispatchQueue.main.async(execute: {
                        processing(progress.fractionCompleted, nil, nil, nil)
                    })
                }
                .responseData { [weak self] response in
                    _ = downloadManager
                    print(response)
                    DispatchQueue.main.async(execute: {
                        switch response.result {
                        case .success:
                            processing(1.0, response.value, response.error, response)
                        case let .failure(error):
                            processing(1.0, nil, error, response)
                        }
                        self?.additionalManagers[uuid] = nil
                    })
            }            
        }
    }
    
    func upload(_ path: String,
                data: Data,
                parameters: Parameters? = nil,
                method: HTTPMethod = .post,
                mime: String? = nil,
                processing: @escaping ASCApiProgressHandler) {
        guard let baseUrl = ASCOnlyOfficeApi.shared.baseUrl else {
            log.error("ASCApi no baseUrl")
            processing(0, nil, nil, nil)
            return
        }
        
        guard
            let encodePath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let portalUrl = URL(string: "\(baseUrl)/\(encodePath).json")
        else {
            log.error("Encoding path")
            processing(0, nil, nil, nil)
            return
        }

        ASCBaseApi.clearCookies(for: portalUrl)

        var headers: HTTPHeaders = [
            "Content-Length": String(data.count)
        ]

        if let mime = mime {
            headers["Content-Type"] = mime
        }
        
        var commonProgress: Double = 0
        let uploadManager = ASCOnlyOfficeApi.createInternalSessionManager(timeoutInterval: 36000)
        
        if var urlComponents = URLComponents(string: portalUrl.absoluteString) {
            var queryItems = urlComponents.queryItems ?? []
            for (key, value) in parameters ?? [:] {
                if let stringValue = value as? String {
                    queryItems.append(URLQueryItem(name: key, value: stringValue))
                }
            }
            urlComponents.queryItems = queryItems
            
            if let uploadUrl = urlComponents.url {
                
                let uuid = UUID()
                additionalManagers[uuid] = uploadManager
                
                uploadManager.upload(data, to: uploadUrl, method: method, headers: headers)
                    .uploadProgress { progress in
                        DispatchQueue.main.async(execute: {
                            commonProgress = progress.fractionCompleted
                            processing(progress.fractionCompleted, nil, nil, nil)
                        })
                }
                .responseJSON { [weak self] response in
                    DispatchQueue.main.async(execute: {
                        _ = uploadManager
                        
                        switch response.result {
                        case .success(let responseJson):
                            if let responseJson = responseJson as? [String: Any] {
                                if let result = responseJson["response"] {
                                    processing(1.0, result, nil, response)
                                    return
                                }
                            }
                            
                            processing(1.0, nil, response.error, response)
                        case .failure(let error):
                            if response.response?.statusCode == 401 {
                                processing(1.0, nil, error, response)
                                return
                            }
                            if commonProgress <= 0.01 {
                                processing(1.0, nil, error, response)
                            }
                            log.error(response)
                        }
                        
                        self?.additionalManagers[uuid] = nil
                    })
                }
            }
        }
    }

    // MARK: - Helpers
    
    static public func errorInfo(by response: Any) -> [String: Any]? {
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
    
    static public func errorMessage(by response: Any) -> String {
        if let errorInfo = self.errorInfo(by: response) {
            if let error = errorInfo["error"] as? [String: Any],
                let message = error["message"] as? String
            {
                return NSLocalizedString(message, comment: "")
            }
        }
        
        return String.localizedStringWithFormat(NSLocalizedString("The %@ server is not available.", comment: ""), ASCOnlyOfficeApi.shared.baseUrl ?? "")
    }
    
    static public func cancelAllTasks() {
        ASCOnlyOfficeApi.shared.manager.session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        
        for (key, value) in ASCOnlyOfficeApi.shared.additionalManagers {
            value.session.getAllTasks { tasks in
                tasks.forEach { $0.cancel() }
            }
            ASCOnlyOfficeApi.shared.additionalManagers[key] = nil
        }
    }

    static public func absoluteUrl(from url: URL?) -> URL? {
        if let url = url {
            if let _ = url.host {
                return url
            } else {
                return URL(string: (ASCOnlyOfficeApi.shared.baseUrl ?? "") + url.absoluteString)
            }
        }
        return nil
    }

    static func createInternalSessionManager(timeoutInterval: TimeInterval) -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutInterval
        configuration.timeoutIntervalForResource = timeoutInterval
        configuration.headers = .default

        let adapter = ASCAccessTokenAdapter(accessToken: ASCOnlyOfficeApi.shared.token ?? "")
        
        let sessionManager = Session(
            configuration: configuration,
            interceptor: Interceptor(adapters: [adapter]),
            serverTrustManager: ASCServerTrustPolicyManager(evaluators: [:])
        )

        return sessionManager
    }
}

extension KingfisherWrapper where Base: KFCrossPlatformImageView {

    @discardableResult
    public func apiSetImage(
        with resource: Resource?,
        placeholder: Placeholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Swift.Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        let modifier = AnyModifier { request in
            var apiRequest = request

            if ASCOnlyOfficeApi.shared.isHttp2 {
                apiRequest.setValue("Bearer \(ASCOnlyOfficeApi.shared.token ?? "")", forHTTPHeaderField: "Authorization")
            } else {
                apiRequest.setValue(ASCOnlyOfficeApi.shared.token, forHTTPHeaderField: "Authorization")
            }

            return apiRequest
        }

        var localOptions = options ?? [.transition(.fade(0.2))]

        // TODO: Hotfix by Linnic. Remove after resolve of conflict between SAAS and Enterprise versions
        if let baseUrl = ASCOnlyOfficeApi.shared.baseUrl,
            let resource = resource,
            URL(string: baseUrl)?.host == resource.downloadURL.host
        {
            localOptions.append(.requestModifier(modifier))
        }

        return setImage(
            with: resource,
            placeholder: placeholder,
            options: localOptions,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }
}
