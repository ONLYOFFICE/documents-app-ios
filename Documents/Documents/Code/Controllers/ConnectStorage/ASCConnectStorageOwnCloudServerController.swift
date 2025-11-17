//
//  ASCConnectStorageOwnCloudServerController.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 3/11/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Alamofire
import CryptoKit
import Foundation
import MBProgressHUD
import UIKit
import WebKit

// MARK: - Models

enum OwnCloudAuthResult {
    case basic(login: String, password: String, serverURL: String)
    case bearer(credential: ASCOAuthCredential, baseURL: URL)
    case error(String)
}

enum ValidationError: LocalizedError {
    case invalidURL
    case serverUnreachable
    case emptyURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("Invalid server URL", comment: "")
        case .serverUnreachable:
            return NSLocalizedString("Server is unreachable", comment: "")
        case .emptyURL:
            return NSLocalizedString("Please enter a server URL", comment: "")
        }
    }
}

final class ASCConnectStorageOwnCloudServerController: UITableViewController {
    // MARK: - Properties

    var completion: (([String: Any]) -> Void)?

    @IBOutlet private var doneCell: UITableViewCell!
    @IBOutlet private var serverCell: UITableViewCell!
    @IBOutlet private var serverField: UITextField!
    @IBOutlet private var doneLabel: UILabel!

    private var serverURL: String = ""

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        serverField.becomeFirstResponder()
    }

    // MARK: - Configuration

    private func configureUI() {
        view.tintColor = Asset.Colors.brend.color
        title = "Owncloud"

        doneCell?.isUserInteractionEnabled = false
        doneLabel?.isEnabled = false

        serverField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }

    // MARK: - Validation

    private func normalizeURL(_ urlString: String) -> String {
        guard !urlString.isEmpty else { return urlString }

        if !urlString.matches(pattern: "^https?://") {
            return urlString.withPrefix("https://")
        }

        return urlString
    }

    private func validateServer(_ urlString: String) async throws -> URL {
        guard !urlString.isEmpty else {
            throw ValidationError.emptyURL
        }

        let normalized = normalizeURL(urlString)

        guard let url = URL(string: normalized),
              UIApplication.shared.canOpenURL(url)
        else {
            throw ValidationError.invalidURL
        }

        // Validate server reachability
        do {
            let _ = try await URLSession.shared.data(from: url)
            log.info("Server URL is valid and reachable: \(url)")
            return url
        } catch {
            log.error("Server is unreachable: \(url), error: \(error)")
            throw ValidationError.serverUnreachable
        }
    }

    // MARK: - Authorization Flow

    private func startAuthFlow() {
        Task {
            await performValidationAndAuth()
        }
    }

    @MainActor
    private func performValidationAndAuth() async {
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Logging in", comment: "Caption of the process")

        defer {
            hud?.hide(animated: true, afterDelay: .shortDelay)
        }

        do {
            let validatedURL = try await validateServer(serverField.text ?? "")
            serverURL = validatedURL.absoluteString

            // Hide HUD before showing web view
            hud?.hide(animated: false)

            showAuthenticationWebView(for: validatedURL)
        } catch {
            serverField.shake()
            doneCell?.isUserInteractionEnabled = false
            doneLabel?.isEnabled = false

            if let validationError = error as? ValidationError {
                UIAlertController.showError(in: self, message: validationError.localizedDescription)
            } else {
                UIAlertController.showError(in: self, message: error.localizedDescription)
            }
        }
    }

    private func showAuthenticationWebView(for baseURL: URL) {
        let oauth2VC = ASCConnectStorageOAuth2Owncloud.instantiate(from: Storyboard.connectStorage)
        let delegate = createOAuthDelegate(for: baseURL, viewController: oauth2VC)

        configureOAuthViewController(oauth2VC, delegate: delegate, baseURL: baseURL)

        navigationController?.pushViewController(oauth2VC, animated: true)
    }

    private func createOAuthDelegate(
        for baseURL: URL,
        viewController: ASCConnectStorageOAuth2Owncloud
    ) -> ASCOwnCloudConnectStorageDelegate {
        let delegate = ASCOwnCloudConnectStorageDelegate()
        delegate.baseURL = baseURL
        delegate.clientId = OwncloudEndpoints.ClientId.web
        delegate.redirectUrl = OwncloudHelper.makeURL(
            base: baseURL,
            addingPath: OwncloudEndpoints.Path.redirectURL
        )?.absoluteString
        delegate.viewController = viewController

        return delegate
    }

    private func configureOAuthViewController(
        _ viewController: ASCConnectStorageOAuth2Owncloud,
        delegate: ASCOwnCloudConnectStorageDelegate,
        baseURL: URL
    ) {
        viewController.responseType = .code
        viewController.delegate = delegate
        viewController.title = "ownCloud"
        viewController.complation = { [weak self] info in
            self?.handleAuthenticationResponse(info, baseURL: baseURL)
        }

        // Configure navigation bar
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.backgroundColor = .systemBackground
        } else {
            navigationController?.navigationBar.backgroundColor = .white
        }
    }

    // MARK: - Authentication Response Handling

    private func handleAuthenticationResponse(_ info: [String: Any], baseURL: URL) {
        guard let authType = info["auth"] as? String else {
            if let error = info["error"] as? String {
                UIAlertController.showError(in: self, message: error)
            }
            return
        }

        switch authType {
        case "Basic":
            handleBasicAuth(info: info)
        case "Bearer":
            handleBearerAuth(info: info, baseURL: baseURL)
        default:
            if let error = info["error"] as? String {
                UIAlertController.showError(in: self, message: error)
            }
        }
    }

    private func handleBasicAuth(info: [String: Any]) {
        guard let login = info["login"] as? String,
              let password = info["password"] as? String
        else {
            if let error = info["error"] as? String {
                UIAlertController.showError(in: self, message: error)
            }
            return
        }

        let params: [String: Any] = [
            "providerKey": ASCFolderProviderType.ownCloud.rawValue,
            "auth": "Basic",
            "login": login,
            "password": password,
            "url": serverURL,
        ]

        completion?(params)
    }

    private func handleBearerAuth(info: [String: Any], baseURL: URL) {
        guard let token = info["token"] as? String,
              let refreshToken = info["refresh_token"] as? String,
              let expiresIn = info["expires_in"] as? Int
        else {
            if let error = info["error"] as? String {
                UIAlertController.showError(in: self, message: error)
            }
            return
        }

        let credential = ASCOAuthCredential(
            accessToken: token,
            refreshToken: refreshToken,
            expiration: Date().adding(.second, value: expiresIn)
        )

        Task {
            await verifyUserAndComplete(baseURL: baseURL, credential: credential)
        }
    }

    @MainActor
    private func verifyUserAndComplete(baseURL: URL, credential: ASCOAuthCredential) async {
        do {
            let userData = try await getCurrentUser(baseURL: baseURL, credential: credential)
            completion?(userData)
        } catch {
            log.error("Failed to verify ownCloud user: \(error.localizedDescription)")
            UIAlertController.showError(
                in: self,
                message: NSLocalizedString("Failed to verify user credentials.", comment: "")
            )
        }
    }

    private func getCurrentUser(
        baseURL: URL,
        credential: ASCOAuthCredential
    ) async throws -> [String: Any] {
        return try await withCheckedThrowingContinuation { continuation in
            let redirectUrl = OwncloudHelper.makeURL(
                base: baseURL,
                addingPath: OwncloudEndpoints.Path.redirectURL
            )?.absoluteString

            let apiClient = OwncloudApiClient(
                clientId: OwncloudEndpoints.ClientId.web,
                redirectUrl: redirectUrl,
                baseURL: baseURL
            )

            apiClient.getCurrentUser(credential: credential) { result in
                switch result {
                case let .success(userData):
                    let params: [String: Any] = [
                        "providerKey": ASCFolderProviderType.ownCloud.rawValue,
                        "auth": "Bearer",
                        "login": userData.preferred_username ?? "",
                        "token": credential.accessToken,
                        "refresh_token": credential.refreshToken,
                        "expires_in": credential.expiration,
                        "url": baseURL.absoluteString,
                    ]
                    continuation.resume(returning: params)

                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Text Field Actions

    @objc private func textFieldDidChange(_ textField: UITextField) {
        let text = textField.text ?? ""
        let isValid = !text.isEmpty

        serverURL = text
        doneCell?.isUserInteractionEnabled = isValid
        doneLabel?.isEnabled = isValid
    }

    // MARK: - Table View Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath)

        if cell == doneCell {
            startAuthFlow()
        }
    }
}
