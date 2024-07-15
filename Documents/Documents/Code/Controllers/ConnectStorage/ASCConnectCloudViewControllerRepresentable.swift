//
//  ASCConnectCloudViewControllerRepresentable.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCConnectCloudViewControllerRepresentable: UIViewControllerRepresentable {
    var completion: ([String: Any]) -> Void

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeUIViewController(context: Context) -> some UIViewController {
        
        let connectStorageVC = ASCConnectPortalThirdPartyViewController.instantiate(from: Storyboard.connectStorage)
        connectStorageVC.captureAuthCompletion = {
            self.completion($0)
        }
        let connectStorageNavigationVC = ASCBaseNavigationController(rootASCViewController: connectStorageVC)

        connectStorageNavigationVC.modalPresentationStyle = .formSheet
        connectStorageNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
        return connectStorageNavigationVC
    }
}
