//
//  ASCFacebookSignInController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/5/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin

typealias ASCFacebookSignInHandler = (_ token: String?, _ error: Error?) -> Void

class ASCFacebookSignInController {
    // MARK: - Properties
    
    private static var initializedSdk: Bool = false
    
    private var signInHandler: ASCFacebookSignInHandler?
    private var presentedController: UIViewController?
    
    // MARK: - Public
    
    func signIn(controller: UIViewController, handler: @escaping ASCFacebookSignInHandler) {
        // Initialize facebook sdk if needed
        if !ASCFacebookSignInController.initializedSdk,
           let appDelegate = UIApplication.shared.delegate as? AppDelegate
        {
            // Initialize Facebook SDK
            Settings.appID = ASCConstants.Clouds.Facebook.appId
            ApplicationDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: appDelegate.launchOptions)
            
            ASCFacebookSignInController.initializedSdk = true
        }
        
        // Sign in
        presentedController = controller
        signInHandler = handler
        
        let loginManager = LoginManager()

        loginManager.logOut()

        loginManager.logIn(permissions: [.publicProfile, .email], viewController: controller) { loginResult in
            switch loginResult {
            case .failed(let error):
                log.error(error)
                self.signInHandler?(nil, error)
            case .cancelled:
                log.info("User cancelled login.")
                self.signInHandler?(nil, nil)
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                log.debug("GRANTED PERMISSIONS: \(grantedPermissions)")
                log.debug("DECLINED PERMISSIONS: \(declinedPermissions)")
                log.debug("ACCESS TOKEN \(accessToken.tokenString)")
                
                self.signInHandler?(accessToken.tokenString, nil)
//                self.signInHandler?(accessToken.authenticationToken, nil)
            }
        }
    }
    
    func signOut() {
        //
    }
    
    static func application(_ app: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Initialize facebook sdk if needed
        if !ASCFacebookSignInController.initializedSdk,
           let appDelegate = UIApplication.shared.delegate as? AppDelegate
        {
            // Initialize Facebook SDK
            Settings.appID = ASCConstants.Clouds.Facebook.appId
            ApplicationDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: appDelegate.launchOptions)
            
            ASCFacebookSignInController.initializedSdk = true
        }
        
        return ApplicationDelegate.shared.application(app, open: url, options: options)
    }
}
