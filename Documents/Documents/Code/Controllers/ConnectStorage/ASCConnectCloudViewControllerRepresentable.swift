//
//  ASCConnectCloudViewControllerRepresentable.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCConnectCloudViewControllerRepresentable: UIViewControllerRepresentable {
    var completion: (ASCFileProviderProtocol, [String: Any]) -> Void

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeUIViewController(context: Context) -> some UIViewController {
        let connectStorageVC = ASCConnectCloudViewController.instantiate(from: Storyboard.connectStorage)
        let navigationVC = UINavigationController(rootViewController: connectStorageVC)

        if #available(iOS 15.0, *) {
            if let sheet = navigationVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.largestUndimmedDetentIdentifier = .large
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersEdgeAttachedInCompactHeight = true
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            }
        } else {
            navigationVC.modalPresentationStyle = .pageSheet
        }

        connectStorageVC.setConnectedToCloudsList = false
        connectStorageVC.complation = completion

        return navigationVC
    }
}
