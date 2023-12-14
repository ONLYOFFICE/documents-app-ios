//
//  MBProgressHUDView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 11.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import MBProgressHUD

enum MBProgressHUDEndStatus {
    case success
    case failure
}

struct MBProgressHUDView: UIViewControllerRepresentable {
    @State var hud: MBProgressHUD?
    @Binding var isLoading: Bool
    var text: String
    var delay: TimeInterval
    var successStatusText: String?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isLoading {
            hud = MBProgressHUD.showAdded(to: uiViewController.view, animated: true)
            hud?.label.text = text
        } else {
            if let successStatusText {
                hud?.setSuccessState(title: successStatusText)
            }
            hud?.hide(animated: true, afterDelay: delay)
        }
    }
}
