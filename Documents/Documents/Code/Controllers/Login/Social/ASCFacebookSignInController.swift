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
    
    private var signInHandler: ASCFacebookSignInHandler?
    private var presentedController: UIViewController?
    
    // MARK: - Public
    
    func signIn(controller: UIViewController, handler: @escaping ASCFacebookSignInHandler) {
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
}
