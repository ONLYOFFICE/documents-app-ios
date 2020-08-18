//
//  Common+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/17/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

public struct ASCCommon {
    public static var appDisplayName: String? {
        // http://stackoverflow.com/questions/28254377/get-app-name-in-swift
        return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
    }
    
    public static var appBundleID: String? {
        return Bundle.main.bundleIdentifier
    }
    
    public static var appVersion: String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    public static var appBuild: String? {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }
    
    public static var currentDevice: UIDevice {
        return UIDevice.current
    }
    
    public static var deviceModel: String {
        return currentDevice.model
    }
        
    public static var systemVersion: String {
        return currentDevice.systemVersion
    }
    
    public static var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
    
    public static var applicationIconBadgeNumber: Int {
        get {
            return UIApplication.shared.applicationIconBadgeNumber
        }
        set {
            UIApplication.shared.applicationIconBadgeNumber = newValue
        }
    }

    public static var isUnitTesting: Bool = {
        return ASCCommon.environment("ASC_UNIT_TESTING") != nil
    }()

    public static func environment(_ name: String) -> String? {
        return ProcessInfo.processInfo.environment[name]
    }
    
    public static func delay(seconds: Double, queue: DispatchQueue = .main, completion: @escaping () -> Void) {
        let task = DispatchWorkItem { completion() }
        queue.asyncAfter(deadline: .now() + seconds, execute: task)
    }
}

func delay(seconds: Double, queue: DispatchQueue = .main, completion: @escaping () -> Void) {
    ASCCommon.delay(seconds: seconds, queue: queue, completion: completion)
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

extension LocalizedError where Self: CustomStringConvertible {
    var errorDescription: String? {
        return description
    }
}
