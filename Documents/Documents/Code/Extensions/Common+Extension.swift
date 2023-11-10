//
//  Common+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/17/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

public enum ASCCommon {
    static var appDisplayName: String? {
        // http://stackoverflow.com/questions/28254377/get-app-name-in-swift
        Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
    }

    static var appBundleID: String? {
        Bundle.main.bundleIdentifier
    }

    static var appVersion: String? {
        if let versionMode = appVersionMode {
            return "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")-\(versionMode)"
        }
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    static var appVersionMode: String? {
        Bundle.main.infoDictionary?["VersionMode"] as? String
    }

    static var appBuild: String? {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }

    static var currentDevice: UIDevice {
        UIDevice.current
    }

    static var deviceModel: String {
        currentDevice.model
    }

    static var systemVersion: String {
        currentDevice.systemVersion
    }

    static var statusBarHeight: CGFloat {
        UIApplication.shared.statusBarFrame.height
    }

    static var applicationIconBadgeNumber: Int {
        get {
            UIApplication.shared.applicationIconBadgeNumber
        }
        set {
            UIApplication.shared.applicationIconBadgeNumber = newValue
        }
    }

    static var isRTL: Bool {
        UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }

    static var isUnitTesting: Bool = ASCCommon.environment("ASC_UNIT_TESTING") != nil

    static func environment(_ name: String) -> String? {
        return ProcessInfo.processInfo.environment[name]
    }

    static func delay(seconds: Double, queue: DispatchQueue = .main, completion: @escaping () -> Void) {
        let task = DispatchWorkItem { completion() }
        queue.asyncAfter(deadline: .now() + seconds, execute: task)
    }
}

func delay(seconds: Double, queue: DispatchQueue = .main, completion: @escaping () -> Void) {
    ASCCommon.delay(seconds: seconds, queue: queue, completion: completion)
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIWindow.keyWindow?.rootViewController) -> UIViewController? {
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
