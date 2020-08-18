//
//  ASCConnectStorageGoogleController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 31.10.2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class ASCConnectStorageGoogleController: NSObject {
    static let identifier = String(describing: ASCConnectStorageGoogleController.self)

    // MARK: - Properties
    
    private let googleDriveService = GTLRDriveService()
    private var googleUser: GIDGoogleUser?
    private let googleSignInController = ASCGoogleSignInController()
    
    var complation: (([String: Any]) -> ())?
    
    // MARK: - Lifecycle Methods
    
    func signIn(parentVC: UIViewController) {
        googleSignInController.signIn(controller: parentVC, scopes: [kGTLRAuthScopeDrive]) { [weak self] token, userData, error in
            var info: [String: Any] = [
                "providerKey": ASCFolderProviderType.googleDrive.rawValue,
            ]
            
            if let token = token {
                info["token"] = token
            }
            if let error = error {
                info["error"] = error.localizedDescription
            }
            if let userData = userData {
                info["user"] = userData
            }
            
            self?.complation?(info)
        }
    }
}

