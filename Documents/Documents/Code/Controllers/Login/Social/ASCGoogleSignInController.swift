//
//  ASCGoogleSignInController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/5/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import FirebaseCore
import GoogleAPIClientForREST
import GoogleSignIn
import UIKit

typealias ASCGoogleSignInHandler = (_ token: String?, _ userData: Data?, _ error: Error?) -> Void

class ASCGoogleSignInController: NSObject {
    // MARK: - Errors

    enum ASCGoogleSignInError: LocalizedError {
        case clientId
        case noGrantedScopes
        case unknown(error: Error?)

        public var errorDescription: String? {
            switch self {
            case .clientId:
                return NSLocalizedString("No client IDs of application", comment: "")
            case .noGrantedScopes:
                return NSLocalizedString("Request had insufficient authentication scopes", comment: "")
            case let .unknown(error):
                return error?.localizedDescription ?? NSLocalizedString("Unknown error", comment: "")
            }
        }
    }

    // MARK: - Properties

    private var signInHandler: ASCGoogleSignInHandler?

    // MARK: - Public

    func signIn(controller: UIViewController, scopes: [String]? = nil, handler: @escaping ASCGoogleSignInHandler) {
        signInHandler = handler

        guard let clientId = FirebaseApp.app()?.options.clientID else {
            signInHandler?(nil, nil, ASCGoogleSignInError.clientId)
            return
        }

        let googleSignIn = GIDSignIn.sharedInstance
        var googleUser: GIDGoogleUser?
        var googleError: Error?

        // Logout
        signOut()

        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        // Base login
        operationQueue.addOperation {
            let semaphore = DispatchSemaphore(value: 0)

            DispatchQueue.main.async {
                googleSignIn.configuration = GIDConfiguration(clientID: clientId)
                googleSignIn.signIn(withPresenting: controller) { result, error in
                    defer { semaphore.signal() }
                    googleUser = result?.user
                    googleError = error
                }
            }
            semaphore.wait()
        }

        // Request additional scopes
        operationQueue.addOperation {
            guard
                let user = googleUser,
                let requestScopes = scopes
            else { return }

            // Check if already have granted scopes
            if let grantedScopes = user.grantedScopes, grantedScopes.contains(requestScopes) {
                return
            }

            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                user.addScopes(requestScopes, presenting: controller) { result, error in
                    defer { semaphore.signal() }
                    googleUser = result?.user
                    googleError = error
                }
            }
            semaphore.wait()
        }

        // Send callback result
        operationQueue.addOperation { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }

                if let error = googleError {
                    strongSelf.signInHandler?(nil, nil, error)
                    return
                }

                guard let user = googleUser else {
                    strongSelf.signInHandler?(nil, nil, ASCGoogleSignInError.noGrantedScopes)
                    return
                }

                // Double check if have granted scopes
                if let requestScopes = scopes {
                    if let grantedScopes = user.grantedScopes, !grantedScopes.contains(requestScopes) {
                        strongSelf.signInHandler?(nil, nil, ASCGoogleSignInError.noGrantedScopes)
                        return
                    }
                }

                strongSelf.signInHandler?(user.accessToken.tokenString, NSKeyedArchiver.archivedData(withRootObject: user), nil)
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        GIDSignIn.sharedInstance.disconnect()
    }
}
