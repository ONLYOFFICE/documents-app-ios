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
    // MARK: - Properties
    
    private var signInHandler: ASCGoogleSignInHandler?

    // MARK: - Public
    
    func signIn(controller: UIViewController, scopes: [String]? = nil, handler: @escaping ASCGoogleSignInHandler) {
        if let googleSignIn = GIDSignIn.sharedInstance() {

            signInHandler = handler

            googleSignIn.presentingViewController = controller
            googleSignIn.clientID = FirebaseApp.app()?.options.clientID
            googleSignIn.scopes = scopes ?? ["email", "profile"]
            googleSignIn.shouldFetchBasicProfile = true
            googleSignIn.delegate = self
            
            // Logout
            signOut()
            
            // Login
            googleSignIn.signIn()
        }
    }
    
    func signOut() {
        if let googleSignIn = GIDSignIn.sharedInstance() {
            googleSignIn.signOut()
            googleSignIn.disconnect()
        }
    }
}

// MARK: - GoogleSignIn Delegate

extension ASCGoogleSignInController: GIDSignInDelegate {

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil, let user = user {
            signInHandler?(user.authentication.accessToken, NSKeyedArchiver.archivedData(withRootObject: user), nil)
        } else {
            signInHandler?(nil, nil, error)
        }
    }
}
