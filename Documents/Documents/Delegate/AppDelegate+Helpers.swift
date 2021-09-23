//
//  AppDelegate+Helpers.swift
//  Documents
//
//  Created by Alexander Yuzhin on 11.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

extension AppDelegate {
    private struct Holder {
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
    
    var passcodeLockPresenter: PasscodeLockPresenter {
        get { return Holder.passcodeLockPresenter }
    }
    
    func initPasscodeLock() {
        _ = passcodeLockPresenter
    }
}
