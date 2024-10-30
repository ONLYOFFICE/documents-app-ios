//
//  ASCTransferViewControllerRepresentable.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.07.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

struct ASCTransferViewControllerRepresentable: UIViewControllerRepresentable {
    var provider: ASCFileProviderProtocol
    var rootFolder: ASCFolder
    var completion: (ASCFolder?, String?) -> Void

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ASCTransferViewController.instantiate(from: Storyboard.transfer)
        let presenter = ASCTransferPresenter(
            view: vc,
            provider: provider,
            transferType: .select,
            enableFillRootFolders: false,
            folder: rootFolder
        )
        vc.presenter = presenter

        vc.actionButton.isEnabled = true

        let nc = ASCTransferNavigationController(rootASCViewController: vc)
        nc.doneHandler = { _, folder, path in
            completion(folder, path)
        }
        nc.displayActionButtonOnRootVC = true
        nc.modalPresentationStyle = .formSheet
        nc.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
        return nc
    }
}
