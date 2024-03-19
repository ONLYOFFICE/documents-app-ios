//
//  ASCRootViewController+ManagedAppConfig.swift
//  Documents
//
//  Created by Alexander Yuzhin on 15.03.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

extension ASCRootViewController: ManagedAppConfigHook {
    func onApp(config: [String: Any?]) {
        handleAppConfig(config: config)
    }
}

extension ASCRootViewController {
    /// {
    ///     "type": "connectPortal",
    ///     "options": {
    ///         "url": "https://example.com"
    ///     }
    /// }

    enum MDMOperationType: String {
        case connectPortal
        case unknown
    }

    private func handleAppConfig(config: [String: Any?]) {
        let type = MDMOperationType(rawValue: config["type"] as? String ?? "") ?? .unknown

        switch type {
        case .connectPortal:
            if let options = config["options"] as? [String: Any],
               let url = options["url"] as? String
            {
                forceConnectPortal(address: url)
            }

        default:
            break
        }

        ManagedAppConfig.shared.setAppConfig(nil)
    }

    private func forceConnectPortal(address: String) {
        ASCUserProfileViewController.logout()

        // Open ONLYOFFICE tab
        selectTab(ofType: ASCOnlyofficeSplitViewController.self)

        // Present connect portal
        if let splitVC = selectedViewController as? UISplitViewController {
            let connectPortalVC = ASCConnectPortalViewController.instance()
            let connectPortalNC = ASCBaseNavigationController(rootASCViewController: connectPortalVC)

            connectPortalNC.modalPresentationStyle = .fullScreen

            delay(seconds: 0.01) {
                splitVC.topMostViewController().present(connectPortalNC, animated: false) {
                    connectPortalVC.forceConnect(to: address)
                }
            }
        }
    }
}
