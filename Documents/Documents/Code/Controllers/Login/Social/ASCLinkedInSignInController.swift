//
//  ASCLinkedInSignInController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 06.08.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCLinkedInSignInController: ASCConnectStorageOAuth2Delegate {
    
    var clientId: String?
    var redirectUrl: String?
    
    weak var viewController: ASCConnectStorageOAuth2ViewController? {
        didSet {
            viewController?.delegate = self
        }
    }
    
    init(clientId: String, redirectUrl: String) {
        self.clientId = clientId
        self.redirectUrl = redirectUrl
    }
    
    func viewDidLoad(controller: ASCConnectStorageOAuth2ViewController) {
        guard let clientId,
              let redirectUrl else { return }
        
        let parameters: [String: String] = [
            "response_type": "code",
            "client_id": clientId,
            "redirect_uri": redirectUrl,
            "scope": "r_liteprofile r_emailaddress w_member_social"
        ]
        
        let authRequest = "https://www.linkedin.com/oauth/v2/authorization?\(parameters.stringAsHttpParameters())"
        guard let url = URL(string: authRequest) else { return }
        let urlRequest = URLRequest(url: url)

        controller.load(request: urlRequest)
    }
    
    func shouldStartLoad(with request: String, in controller: ASCConnectStorageOAuth2ViewController) -> Bool {
        log.info("webview url = \(request)")

        if let errorCode = controller.getQueryStringParameter(url: request, param: "error") {
            log.error("code: \(errorCode)")
            controller.complation?([
                "error": String(format: NSLocalizedString("Please retry. \n\n If the problem persists contact us and mention this error code: Linkedin - %@", comment: ""), errorCode),
            ])
            return false
        }

        if let redirectUrl = redirectUrl, request.contains(redirectUrl),
           let code = controller.getQueryStringParameter(url: request, param: "code")
        {
            controller.complation?([
                "code": code,
            ])
            return false
        }
        return true
    }
}
