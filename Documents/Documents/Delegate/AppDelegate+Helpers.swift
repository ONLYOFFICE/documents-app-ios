//
//  AppDelegate+Helpers.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

extension AppDelegate {
    private enum Holder {
        static var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        static var passcodeLockPresenter: PasscodeLockPresenter = {
            let configuration = ASCPasscodeLockConfiguration()
            let presenter = ASCPasscodeLockPresenter(mainWindow: UIApplication.shared.delegate?.window as? UIWindow, configuration: configuration)

            return presenter
        }()
    }

    var launchOptions: [UIApplication.LaunchOptionsKey: Any]? {
        get { return Holder.launchOptions }
        set { Holder.launchOptions = newValue }
    }

    var passcodeLockPresenter: PasscodeLockPresenter { return Holder.passcodeLockPresenter }

    func initPasscodeLock() {
        _ = passcodeLockPresenter
    }

    func initializeDI() {
        ASCDIContainer.shared.register(type: ASCEditorManagerOptionsProtocol.self, service: ASCEditorManagerOptions())
        ASCDIContainer.shared.register(type: ASCDocumentEditorExternalSettingsProtocol.self, service: ASCDocumentEditorExternalSettings())
        ASCDIContainer.shared.register(type: ASCSpreadsheetEditorExternalSettingsProtocol.self, service: ASCSpreadsheetEditorExternalSettings())
        ASCDIContainer.shared.register(type: ASCPresentationEditorExternalSettingsProtocol.self, service: ASCPresentationEditorExternalSettings())
    }
}
