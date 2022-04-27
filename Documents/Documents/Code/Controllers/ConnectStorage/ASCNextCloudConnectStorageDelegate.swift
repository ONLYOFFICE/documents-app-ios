//
//  ASCNextCloudConnectStorageDelegate.swift
//  Documents
//
//  Created by Лолита Чернышева on 04.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCNextCloudConnectStorageDelegate: ASCConnectStorageOAuth2Delegate {
    var clientId: String?
    var redirectUrl: String?
    private var loginHeader = "OCS-APIREQUEST"

    var url: URL?

    weak var viewController: ASCConnectStorageOAuth2ViewController? {
        didSet {
            viewController?.delegate = self
        }
    }

    func viewDidLoad(controller: ASCConnectStorageOAuth2ViewController) {
        guard let url = url else { return }
        var urlRequest = URLRequest(url: url)

        urlRequest.setValue("true", forHTTPHeaderField: loginHeader)
        controller.load(request: urlRequest)
    }

    func shouldStartLoad(with request: String, in controller: ASCConnectStorageOAuth2ViewController) -> Bool {
        log.info("webview url = \(request)")
        if request.contains(["user", "password"]) {
            let separated = request.components(separatedBy: "&")
            guard let loginString = separated.filter({ $0.contains("user") }).first,
                  let passwordString = separated.filter({ $0.contains("password") }).first,
                  let login = loginString.split(separator: ":").last,
                  let password = passwordString.split(separator: ":").last
            else {
                return true
            }

            viewController?.complation?([
                "user": String(login),
                "password": String(password),
            ])
            return false
        }
        return true
    }
}
