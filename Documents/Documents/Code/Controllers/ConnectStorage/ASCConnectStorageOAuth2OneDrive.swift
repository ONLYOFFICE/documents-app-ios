//
//  ASCConnectStorageOAuth2OneDrive.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/16/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire

class ASCConnectStorageOAuth2OneDrive: ASCConnectStorageOAuth2Delegate {
    // MARK: - Properties
    
    let authorizeUrl = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
    let tokenUrl = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
    let scope = "User.Read files.readwrite.all offline_access"
    
    weak var viewController: ASCConnectStorageOAuth2ViewController? {
        didSet {
            viewController?.delegate = self
        }
    }
    var clientId: String?
    var clientSecret: String?
    var redirectUrl: String?
    
    // MARK: - ASCConnectStorageOAuth2 Delegate
    
    func viewDidLoad(controller: ASCConnectStorageOAuth2ViewController) {
        let parameters: [String: String] = [
            "response_type" : controller.responseType == .code ? "code" : "token",
            "scope"         : scope,
            "client_id"     : clientId ?? "",
            "redirect_uri"  : redirectUrl ?? ""
        ]
        
        let authRequest = "\(authorizeUrl)?\(parameters.stringAsHttpParameters())"
        let urlRequest = URLRequest(url: URL(string: authRequest)!)
        
        UserDefaults.standard.register(defaults: ["UserAgent": "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/603.1.23 (KHTML, like Gecko) Version/10.0 Mobile/14E5239e Safari/602.1"])
        controller.load(request: urlRequest)
    }
    
    func shouldStartLoad(with request: String, in controller: ASCConnectStorageOAuth2ViewController) -> Bool {
        log.info("webview url = \(request)")
        
        if let errorCode = controller.getQueryStringParameter(url: request, param: "error") {
            log.error("Code: \(errorCode)")
            
            if let topViewController = controller.navigationController?.topViewController {
                UIAlertController.showError(
                    in: topViewController,
                    message: String(format: NSLocalizedString("Please retry. \n\n If the problem persists contact us and mention this error code: OneDrive - %@", comment: ""), errorCode)
                )
                controller.navigationController?.popViewController(animated: true)
            }
            return false
        }
        if let redirectUrl = redirectUrl, request.contains(redirectUrl) {
            if controller.responseType == .code {
                if let code = controller.getQueryStringParameter(url: request, param: "code") {
                    
                    let parameters = [
                        "client_id": clientId ?? "",
                        "redirect_uri": redirectUrl,
                        "client_secret": clientSecret ?? "",
                        "code": code,
                        "grant_type": "authorization_code",
                    ]
                    
                    let httpHeaders = HTTPHeaders(["Content-Type": "application/x-www-form-urlencoded"])
                    
                    AF.request(
                        tokenUrl,
                        method: .post,
                        parameters: parameters,
                        encoding: URLEncoding.httpBody,
                        headers: httpHeaders
                    ).responseDecodable(of: AuthByCodeResponseModel.self) { response in
                        switch response.result {
                        case .success(let model):
                            log.info(model)
                            controller.complation?([
                                "providerKey": ASCFolderProviderType.oneDrive.rawValue,
                                "token": model.access_token,
                                "refresh_token": model.refresh_token
                            ])
                        case .failure(let error):
                            log.error(error)
                        }
                    }
                    
                    return false
                }
            } else {
                var correctRequest = request
                
                if request.contains(redirectUrl + "#") {
                    correctRequest = request.replacingOccurrences(of: redirectUrl + "#", with: redirectUrl + "?")
                }

                if let token = controller.getQueryStringParameter(url: correctRequest, param: "access_token") {
                    controller.complation?([
                        "providerKey": ASCFolderProviderType.oneDrive.rawValue,
                        "token": token
                    ])
                    return false
                }
            }
        }
        return true
    }
}

extension ASCConnectStorageOAuth2OneDrive {
    struct AuthByCodeResponseModel: Codable {
        var token_type: String
        var expires_in: Int
        var scope: String
        var access_token: String
        var refresh_token: String
    }
}
