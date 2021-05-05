//
//  ASCSSOSignInController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 8/28/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import WebKit

typealias ASCSSOSignInHandler = (_ token: String?, _ error: Error?) -> Void

class ASCSSOSignInController: UIViewController {

    // MARK: - Properties
    
    var webView: WKWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var signInHandler: ASCSSOSignInHandler?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        view.insertSubview(webView, at: 0)
        
        webView.fillToSuperview()
        webView.navigationDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }
    
    func signIn(ssoUrl: String, handler: @escaping ASCSSOSignInHandler) {
        signInHandler = handler

        removeCookies()

        if var components = URLComponents(string: ssoUrl) {
            var queryItems = components.queryItems ?? []
            queryItems.append(URLQueryItem(name: "_dc", value: Date().string(withFormat: "HHmmssSSS")))
            components.queryItems = queryItems

            if let url = components.url {
                webView?.load(URLRequest(url: url))
            }
        }
    }

    private func removeCookies() {
        URLCache.shared.removeAllCachedResponses()

        let cookieJar = HTTPCookieStorage.shared

        for cookie in cookieJar.cookies ?? [] {
            cookieJar.deleteCookie(cookie)
        }
    }
    
    private func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

    // MARK: - Actions
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - WKNavigation Delegate

extension ASCSSOSignInController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        log.info("webview url = \(navigationAction.request)")
        
        guard
            let host = navigationAction.request.url?.host,
            let urlString = navigationAction.request.url?.absoluteString
        else {
            decisionHandler(.cancel)
            return
        }

        title = host
        
        if let errorCode = getQueryStringParameter(url: urlString, param: "error") ?? getQueryStringParameter(url: urlString, param: "m") {
            log.error("Code: \(errorCode)")
            signInHandler?(nil, NSError(domain: "SSOError", code: 0, userInfo: [
                NSLocalizedDescriptionKey: errorCode
            ]))
            navigationController?.dismiss(animated: true, completion: nil)
            decisionHandler(.cancel)
            return
        }
        
        if let token = getQueryStringParameter(url: urlString, param: "token") {
            navigationController?.dismiss(animated: false, completion: nil)
            signInHandler?(token, nil)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator?.stopAnimating()
        activityIndicator?.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        log.error(error)
        
        let alertController = UIAlertController(
            title: ASCLocalization.Common.error,
            message: error.localizedDescription,
            preferredStyle: .alert,
            tintColor: nil
        )
        
        alertController.addAction(UIAlertAction(title: ASCLocalization.Common.ok, style: .default, handler: { [weak self] action in
            self?.dismiss(animated: true, completion: nil)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
}
