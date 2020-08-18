//
//  ASCConnectStorageOAuth2ViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/16/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import WebKit

enum ASCConnectStorageOAuth2ResponseType {
    case code, token
}

protocol ASCConnectStorageOAuth2Delegate {
    var clientId: String? { get set }
    var redirectUrl: String? { get set }

    func viewDidLoad(controller: ASCConnectStorageOAuth2ViewController)
    func shouldStartLoad(with request: String, in controller: ASCConnectStorageOAuth2ViewController) -> Bool
}

class ASCConnectStorageOAuth2ViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var responseType: ASCConnectStorageOAuth2ResponseType = .code
    var webView: WKWebView!
    var delegate: ASCConnectStorageOAuth2Delegate?
    var complation: (([String: Any]) -> ())?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        view.insertSubview(webView, at: 0)
        
        webView.fillToSuperview()
        webView.navigationDelegate = self
        
        delegate?.viewDidLoad(controller: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Public
    
    func load(request: URLRequest) {
        webView?.load(request)
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

}

// MARK: - WKNavigation Delegate

extension ASCConnectStorageOAuth2ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let urlString = navigationAction.request.url?.absoluteString else {
            decisionHandler(.cancel)
            return
        }
        
        let shouldStartLoad = delegate?.shouldStartLoad(with: urlString, in: self) ?? true
        decisionHandler(shouldStartLoad ? .allow : .cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        indicator?.stopAnimating()
        indicator?.isHidden = true
    }
}
