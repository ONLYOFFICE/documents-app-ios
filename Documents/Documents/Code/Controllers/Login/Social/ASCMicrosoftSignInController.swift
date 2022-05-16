//
//  ASCMicrosoftSignInController.swift
//  Documents
//
//  Created by Лолита Чернышева on 19.02.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCMicrosoftSignInController: ASCConnectStorageOAuth2Delegate {
    var clientId: String?
    var redirectUrl: String?

    weak var viewController: ASCConnectStorageOAuth2ViewController? {
        didSet {
            viewController?.delegate = self
        }
    }

    func viewDidLoad(controller: ASCConnectStorageOAuth2ViewController) {
        let parameters: [String: String] = [
            "response_type": "code",
            "client_id": clientId ?? "",
            "redirect_uri": redirectUrl ?? "",
            "scope": "openid email profile",
            "response_mode": "query",
        ]

        let authRequest = "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize?\(parameters.stringAsHttpParameters())"
        guard let url = URL(string: authRequest) else { return }
        let urlRequest = URLRequest(url: url)

        controller.load(request: urlRequest)
    }

    func shouldStartLoad(with request: String, in controller: ASCConnectStorageOAuth2ViewController) -> Bool {
        log.info("webview url = \(request)")

        if let errorCode = controller.getQueryStringParameter(url: request, param: "error") {
            log.error("code: \(errorCode)")
            controller.complation?([
                "error": String(format: NSLocalizedString("Please retry. \n\n If the problem persists contact us and mention this error code: Microsoft - %@", comment: ""), errorCode),
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
