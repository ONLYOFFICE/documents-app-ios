//
//  ASCConnectStorageNextCloudServerController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 02.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import MBProgressHUD
import UIKit
import WebKit

class ASCConnectStorageNextCloudServerController: UITableViewController {
    // MARK: - Properties

    var complation: (([String: String]) -> Void)?

    @IBOutlet var serverField: UITextField!
    @IBOutlet var serverCell: UITableViewCell!
    @IBOutlet var doneCell: UITableViewCell!
    @IBOutlet var doneLabel: UILabel!
    @IBOutlet var logoView: UIImageView!

    private var keyPortal = "KEY_PORTAL"
    private var loginSuffix = "/index.php/login/flow"
    private var loginHeader = "OCS-APIREQUEST"
    private var backPattern1 = "apps"
    private var backPattern2 = "files"
    private var urlString: String = ""

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Nextcloud"

        doneCell?.isUserInteractionEnabled = false
        doneLabel?.isEnabled = false

        serverField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        serverField?.becomeFirstResponder()
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        var allowDone = true

        defer {
            doneCell?.isUserInteractionEnabled = allowDone
            doneLabel.isEnabled = allowDone
        }

        if let server = serverField?.text {
            allowDone = allowDone && !server.isEmpty
        }
        urlString = textField.text ?? ""
    }

    private func showWebView() {
        guard let url = URL(string: urlString + loginSuffix) else { return }
        let nextCloudDelegate = ASCNextCloudConnectStorageDelegate()
        nextCloudDelegate.url = url
        let oauth2VC = ASCConnectStorageOAuth2ViewController.instantiate(from: Storyboard.connectStorage)
        nextCloudDelegate.viewController = oauth2VC
        oauth2VC.complation = { [weak self] info in

            guard let self = self else { return }

            if let login = info["user"] as? String,
               let password = info["password"] as? String
            {
                var params: [String: String] = [
                    "providerKey": ASCFolderProviderType.nextCloud.rawValue,
                    "login": login,
                    "password": password,
                ]

                params["url"] = urlString

                self.complation?(params)
            } else if let error = info["error"] as? String {
                UIAlertController.showError(in: self, message: error)
            }
        }

        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.backgroundColor = .systemBackground
        } else {
            navigationController?.navigationBar.backgroundColor = .white
        }

        navigationController?.pushViewController(oauth2VC, animated: true)
    }

    private func valid(portal: String, completion: @escaping (Bool) -> Void) {
        if !portal.isEmpty, !portal.matches(pattern: "^https?://") {
            urlString = portal.withPrefix("https://")
        }

        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            completion(false)
            return
        }

        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")
        (URLSession.shared.dataTask(with: url as URL) { data, response, error in
            DispatchQueue.main.async {
                hud?.hide(animated: true, afterDelay: .shortDelay)
                guard data != nil else {
                    log.error("url is anavailable \(url)")
                    completion(false)
                    return
                }
                log.info("url is correct \(url)")
                completion(true)
            }
        }).resume()
    }
}

// MARK: - TableView Delegate

extension ASCConnectStorageNextCloudServerController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if cell == doneCell {
            valid(portal: serverField.text ?? "") { [weak self] isSuccess in

                guard let self = self else { return }
                if isSuccess {
                    self.showWebView()
                } else {
                    self.serverField?.shake()
                    self.doneLabel.isUserInteractionEnabled = false
                }
            }
        }
    }
}
