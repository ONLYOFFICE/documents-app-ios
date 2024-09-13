//
//  CopyFileInsideProviderService.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 13.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol CopyFileInsideProviderService {
    func copyFileInsideProvider(
        provider: ASCFileProviderProtocol?,
        file: ASCFile,
        viewController: ASCDocumentsViewController?
    )
}

final class CopyFileInsideProviderServiceImp: CopyFileInsideProviderService {
    func copyFileInsideProvider(
        provider: ASCFileProviderProtocol?,
        file: ASCFile,
        viewController: ASCDocumentsViewController?
    ) {
        guard let srcProvider = provider,
              let destProvider = provider,
              let viewController,
              let destFolder = viewController.folder
        else { return }
        var forceCancel = false
        let transferAlert = ASCProgressAlert(
            title: .copying,
            message: nil,
            handler: { cancel in
                forceCancel = cancel
            }
        )
        transferAlert.show()
        transferAlert.progress = 0

        ASCEntityManager.shared.transfer(
            from: (items: [file], provider: srcProvider),
            to: (folder: destFolder, provider: destProvider),
            move: false
        ) { progress, complate, success, newItems, error, cancel in
            if forceCancel {
                cancel = forceCancel
            }
            DispatchQueue.main.async { [viewController] in
                if complate {
                    transferAlert.hide()
                    if success {
                        viewController.loadFirstPage()
                    }
                    if !ASCNetworkReachability.shared.isReachable {
                        UIAlertController.showError(in: viewController, message: .checkInternetConnection)
                    } else if !success, let error = error {
                        UIAlertController.showError(in: viewController, message: error.localizedDescription)
                    }
                } else {
                    transferAlert.progress = progress
                }
            }
        }
    }
}

private extension String {
    static var checkInternetConnection: String {
        NSLocalizedString("Check your internet connection", comment: "")
    }

    static var copying: String {
        NSLocalizedString("Copying", comment: "Caption of the processing")
    }
}
