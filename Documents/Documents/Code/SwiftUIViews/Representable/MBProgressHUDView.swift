//
//  MBProgressHUDView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 11.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import MBProgressHUD

struct MBProgressHUDView: UIViewControllerRepresentable {
    @Binding var isLoading: Bool
    var text: String
    var delay: TimeInterval 

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isLoading {
            let hud = MBProgressHUD.showAdded(to: uiViewController.view, animated: true)
            hud.label.text = text
            hud.hide(animated: true, afterDelay: delay)
        } else {
            MBProgressHUD.hide(for: uiViewController.view, animated: true)
        }
    }
}
