//
//  ASCGoogleSignInController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/5/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseCore

typealias ASCGoogleSignInHandler = (_ token: String?, _ userData: Data?, _ error: Error?) -> Void

class ASCGoogleSignInController: NSObject {
    // MARK: - Errors
    
    enum ASCGoogleSignInError: LocalizedError {
        case clientId
        
        public var errorDescription: String? {
            switch self {
            case .clientId:
                return NSLocalizedString("No client IDs of application", comment: "")
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
        
        // Logout
        signOut()
        
        // Login
        let signInConfig = GIDConfiguration(clientID: clientId)
        googleSignIn.signIn(with: signInConfig, presenting: controller) { [weak self] user, error in
            guard let user = user else {
                self?.signInHandler?(nil, nil, error)
                return
            }
            // TODO: Check user.grantedScopes or GIDSignIn.sharedInstance.addScopes
            self?.signInHandler?(user.authentication.accessToken, NSKeyedArchiver.archivedData(withRootObject: user), nil)
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        GIDSignIn.sharedInstance.disconnect()
    }
}
