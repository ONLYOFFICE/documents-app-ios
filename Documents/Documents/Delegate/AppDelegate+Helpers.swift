//
//  AppDelegate+Helpers.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import PasscodeLock
import UIKit

extension AppDelegate {
    private enum Holder {
        static var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    }

    var launchOptions: [UIApplication.LaunchOptionsKey: Any]? {
        get { return Holder.launchOptions }
        set { Holder.launchOptions = newValue }
    }

    func initializeDI() {
        ASCDIContainer.shared.register(type: ASCIntroPageStoreProtocol.self, service: ASCIntroPageStore())
        ASCDIContainer.shared.register(type: ASCEditorManagerOptionsProtocol.self, service: ASCEditorManagerOptions())
        ASCDIContainer.shared.register(type: ASCDocumentEditorConfigurationProtocol.self, service: ASCDocumentEditorConfiguration())
        ASCDIContainer.shared.register(type: ASCSpreadsheetEditorConfigurationProtocol.self, service: ASCSpreadsheetEditorConfiguration())
        ASCDIContainer.shared.register(type: ASCPresentationEditorConfigurationProtocol.self, service: ASCPresentationEditorConfiguration())
    }

    func showUpdateAlert(appstoreURL: URL?) {
        guard let url = appstoreURL else { return }

        let alert = UIAlertController(
            title: NSLocalizedString("Update Available", comment: ""),
            message: NSLocalizedString("Please install the latest version of the app.", comment: ""),
            preferredStyle: .alert
        )

        let laterAction = UIAlertAction(title: NSLocalizedString("Later", comment: ""), style: .cancel, handler: nil)

        let updateAction = UIAlertAction(title: NSLocalizedString("Update", comment: ""), style: .default) { _ in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }

        alert.addAction(laterAction)
        alert.addAction(updateAction)

        if let rootVC = UIWindow.keyWindow?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}
