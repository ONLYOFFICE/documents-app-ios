//
//  ASCConnectStorageOAuth2Google.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/17/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCConnectStorageOAuth2Google: ASCConnectStorageOAuth2Delegate {

    // MARK: - Properties
    
    weak var viewController: ASCConnectStorageOAuth2ViewController? {
        didSet {
            viewController?.delegate = self
        }
    }
    var clientId: String?
    var redirectUrl: String?
    
    // MARK: - ASCConnectStorageOAuth2 Delegate
    
    func viewDidLoad(controller: ASCConnectStorageOAuth2ViewController) {
        let parameters: [String: String] = [
            "access_type"        : "offline",
            "response_type"      : "code",
            "approval_prompt"    : "force",
            "scope"              : "https://www.googleapis.com/auth/drive",
            "client_id"          : clientId ?? "",
            "redirect_uri"       : redirectUrl ?? ""
        ]
        
        let authRequest = "https://accounts.google.com/o/oauth2/auth?\(parameters.stringAsHttpParameters())"
        let urlRequest = URLRequest(url: URL(string: authRequest)!)
        let  customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/603.1.23 (KHTML, like Gecko) Version/10.0 Mobile/14E5239e Safari/602.1"
        
        UserDefaults.standard.register(defaults: ["UserAgent": customUserAgent])
        
        controller.webView?.customUserAgent = customUserAgent
        controller.load(request: urlRequest)
    }
    
    func shouldStartLoad(with request: String, in controller: ASCConnectStorageOAuth2ViewController) -> Bool {
        log.info("webview url = \(request)")
        
        if let errorCode = controller.getQueryStringParameter(url: request, param: "error") {
            log.error("Code: \(errorCode)")
            
            if let topViewController = controller.navigationController?.topViewController {
                UIAlertController.showError(
                    in: topViewController,
                    message: String(format: NSLocalizedString("Please retry. \n\n If the problem persists contact us and mention this error code: Google - %@", comment: ""), errorCode))
                controller.navigationController?.popViewController(animated: true)
            }
            return false
        }
        
        if let code = controller.getQueryStringParameter(url: request, param: "code") {
            controller.complation?([
                "providerKey": ASCFolderProviderType.googleDrive.rawValue,
                "token": code
            ])
            return false
        }
        
        return true
    }
    
}
