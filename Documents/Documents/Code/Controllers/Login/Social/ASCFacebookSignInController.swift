//
//  ASCFacebookSignInController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/5/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import FBSDKCoreKit
import FBSDKLoginKit
import UIKit

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
            Settings.shared.appID = ASCConstants.Clouds.Facebook.appId
            Settings.shared.clientToken = ASCConstants.Clouds.Facebook.clientToken
            ApplicationDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: appDelegate.launchOptions)

            ASCFacebookSignInController.initializedSdk = true
        }

        // Sign in
        presentedController = controller
        signInHandler = handler

        let loginManager = LoginManager()

        loginManager.logOut()

        let permissions: [Permission] = [.publicProfile, .email]
        loginManager.logIn(permissions: permissions.map { $0.name }, from: controller) { loginResult, error in
            if let error {
                log.error(error)
                self.signInHandler?(nil, error)
                return
            }

            if let result = loginResult {
                if result.isCancelled {
                    log.info("User cancelled login.")
                    self.signInHandler?(nil, nil)
                } else {
                    log.debug("GRANTED PERMISSIONS: \(result.grantedPermissions)")
                    log.debug("DECLINED PERMISSIONS: \(result.declinedPermissions)")
                    log.debug("ACCESS TOKEN \(result.token?.tokenString ?? "none")")

                    self.signInHandler?(result.token?.tokenString, nil)
                }
            }
        }
    }

    func signOut() {
        //
    }

    static func application(_ app: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool
    {
        // Initialize facebook sdk if needed
        if !ASCFacebookSignInController.initializedSdk,
           let appDelegate = UIApplication.shared.delegate as? AppDelegate
        {
            // Initialize Facebook SDK
            Settings.shared.appID = ASCConstants.Clouds.Facebook.appId
            Settings.shared.clientToken = ASCConstants.Clouds.Facebook.clientToken
            ApplicationDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: appDelegate.launchOptions)

            ASCFacebookSignInController.initializedSdk = true
        }

        return ApplicationDelegate.shared.application(app, open: url, options: options)
    }
}
