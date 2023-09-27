//
//  ASCWebKitViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 04.02.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit
import WebKit

class ASCWebKitViewController: ASCBaseViewController {
    private let webView = WKWebView()
    private let urlString: String

    init(urlString: String) {
        self.urlString = urlString
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        configure()
        loadUrl()
    }

    // MARK: private

    private func configure() {
        configureWebView()
        configureBarButton()
    }

    private func configureWebView() {
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.fillToSuperview()
    }

    private func configureBarButton() {
        let backItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""),
                                       style: .done,
                                       target: self,
                                       action: #selector(didTappedDone))
        navigationItem.leftBarButtonItem = backItem
    }

    private func loadUrl() {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    @objc private func didTappedDone() {
        dismiss(animated: true, completion: nil)
    }
}
