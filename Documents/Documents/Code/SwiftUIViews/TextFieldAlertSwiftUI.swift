//
//  TextFieldAlertSwiftUI.swift
//  Documents
//
//  Created by Lolita Chernysheva on 23.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import UIKit

struct TextFieldAlertSwiftUIModel {
    let title: String
    let message: String?
    var placeholder: String = ""
    var accept: String = ""
    var cancel: String = ""
    var action: (String?) -> Void
}

struct TextFieldAlertSwiftUI: UIViewControllerRepresentable {
    class Coordinator {
        var alert: UIAlertController?
    }

    @Binding var isPresented: Bool
    let alert: TextFieldAlertSwiftUIModel

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard context.coordinator.alert == nil, isPresented else { return }

        let alertController = UIAlertController(
            title: alert.title,
            message: alert.message,
            preferredStyle: .alert
        )

        alertController.addTextField {
            $0.placeholder = alert.placeholder
        }

        alertController.addAction(UIAlertAction(title: alert.cancel, style: .cancel) { _ in
            isPresented = false
        })

        alertController.addAction(UIAlertAction(title: alert.accept, style: .default) { _ in
            let text = alertController.textFields?.first?.text
            alert.action(text)
            isPresented = false
        })

        context.coordinator.alert = alertController
        uiViewController.present(alertController, animated: true, completion: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}
