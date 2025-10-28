//
//  ASCAppleIdSignInController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 13.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import AuthenticationServices
import Foundation
import MBProgressHUD
import UIKit

typealias AppleIdAuthorizationCode = String

class ASCAppleIdSignInController: NSObject {
    private lazy var viewController: UIViewController = UIViewController()
    private var completionHandler: (Result<AppleIdAuthorizationCode, Error>) -> Void = { _ in }

    func signIn(controller: UIViewController, handler: @escaping (Result<AppleIdAuthorizationCode, Error>) -> Void) {
        viewController = controller
        completionHandler = handler

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()

        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension ASCAppleIdSignInController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        viewController.view.window!
    }
}

extension ASCAppleIdSignInController: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let code = appleIDCredential.authorizationCode,
              let codeStr = AppleIdAuthorizationCode(data: code, encoding: .utf8)
        else {
            completionHandler(.failure(Errors.appleIdAuthFailed))
            return
        }

        completionHandler(.success(codeStr))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        completionHandler(.failure(error))
    }
}

extension ASCAppleIdSignInController {
    enum Errors: Error, LocalizedError {
        case appleIdAuthFailed

        var errorDescription: String? {
            switch self {
            case .appleIdAuthFailed:
                return NSLocalizedString("AppleId authentication failed", comment: "")
            }
        }
    }
}
