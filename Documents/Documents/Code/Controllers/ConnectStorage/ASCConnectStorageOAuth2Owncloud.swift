//
//  ASCConnectStorageOAuth2Owncloud.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 5/11/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import WebKit

final class ASCConnectStorageOAuth2Owncloud: ASCConnectStorageOAuth2ViewController {
    @discardableResult
    private func handleWebdavAuthIfNeeded(navigationAction: WKNavigationAction) -> Bool {
        let method = navigationAction.request.httpMethod ?? "GET"
        guard method == "POST" else { return false }

        guard
            let url = navigationAction.request.url,
            url.path.contains("/login") || url.path.contains("/index.php/login")
        else { return false }

        if let body = navigationAction.request.httpBody,
           let bodyString = String(data: body, encoding: .utf8)
        {
            let (user, password) = parseFormURLEncodedBody(bodyString)

            DispatchQueue.main.async { [weak self] in
                self?.indicator?.startAnimating()
                self?.complation?([
                    "auth": "Basic",
                    "login": user,
                    "password": password,
                ])
            }
        } else {
            complation?(["error": "Authentication failed"])
        }

        return true
    }

    private func parseFormURLEncodedBody(_ body: String) -> (user: String, password: String) {
        let decoded = body.removingPercentEncoding ?? body
        var params: [String: String] = [:]

        for pair in decoded.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                params[parts[0]] = parts[1]
            }
        }

        let user = params["user"] ?? ""
        let password = params["password"] ?? ""
        return (user, password)
    }
}

// MARK: - ownCloud-specific WKNavigationDelegate

extension ASCConnectStorageOAuth2Owncloud {
    override func webView(_ webView: WKWebView,
                          decidePolicyFor navigationAction: WKNavigationAction,
                          decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        guard let urlString = navigationAction.request.url?.absoluteString else {
            decisionHandler(.cancel)
            return
        }

        if handleWebdavAuthIfNeeded(navigationAction: navigationAction) {
            decisionHandler(.cancel)
            return
        }

        let shouldStart = delegate?.shouldStartLoad(with: urlString, in: self) ?? true
        decisionHandler(shouldStart ? .allow : .cancel)
    }

    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        super.webView(webView, didFinish: navigation)
    }
}
