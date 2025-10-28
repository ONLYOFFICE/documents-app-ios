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
}
