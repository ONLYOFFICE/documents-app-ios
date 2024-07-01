//
//  ASCConnectCloudViewControllerRepresentable.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCConnectCloudViewControllerRepresentable: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeUIViewController(context: Context) -> some UIViewController {
        return ASCConnectCloudViewController.instantiate(from: Storyboard.connectStorage)
    }
}
