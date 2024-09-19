//
//  CompleteFormMailView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 13.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI
import MessageUI

struct CompleteFormMailView: UIViewControllerRepresentable {
    @Binding var data: ComposeMailData
    var callback: (Result<MFMailComposeResult, Error>) -> Void

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: CompleteFormMailView
        var callback: (Result<MFMailComposeResult, Error>) -> Void

        init(parent: CompleteFormMailView, callback: @escaping (Result<MFMailComposeResult, Error>) -> Void) {
            self.parent = parent
            self.callback = callback
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
            if let error = error {
                callback(.failure(error))
            } else {
                callback(.success(result))
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self, callback: callback)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setSubject(data.subject)
        vc.setToRecipients(data.recipients)
        vc.setMessageBody(data.messageBody, isHTML: data.isHtml)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

struct ComposeMailData {
    var subject: String
    var recipients: [String]
    var messageBody: String
    var isHtml: Bool = false
}
