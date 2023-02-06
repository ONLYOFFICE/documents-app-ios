//
//  ASCDebugManager.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import Pulse
import PulseUI
import SwiftUI
import UIKit

class ASCDebugManager: NSObject {
    public static let shared = ASCDebugManager()

    public var enabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: isDebugModeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: isDebugModeKey)
        }
    }

    fileprivate let isDebugModeKey = "asc.debug.mode"
    fileprivate var presented: Bool = false
    fileprivate var presentingViewController: UIViewController? {
        var rootViewController = UIWindow.keyWindow?.rootViewController
        while let controller = rootViewController?.presentedViewController {
            rootViewController = controller
        }
        return rootViewController
    }

    fileprivate func toggleDebugMenu() {
        presented ? hideDebugMenu() : showDebugMenu()
    }

    public func showDebugMenu() {
        if presented {
            return
        }

        let debugNV = ASCDebugNavigationController.instantiate(from: Storyboard.debug)
        debugNV.onDismissed = {
            self.presented = false
        }

        if #available(iOS 13.0, *) {
            debugNV.presentationController?.delegate = self
        }

        debugNV.viewControllers = [
            UIHostingController(rootView: ConsoleView()),
        ]

        presentingViewController?.present(debugNV, animated: true, completion: nil)

        presented = true
    }

    fileprivate func hideDebugMenu() {
        if !presented {
            return
        }

        presentingViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.presented = false
        })
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension ASCDebugManager: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        presented = false
    }
}

// MARK: - UIWindow extension

extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if ASCDebugManager.shared.enabled {
            if event!.type == .motion && event!.subtype == .motionShake {
                ASCDebugManager.shared.toggleDebugMenu()
                return
            }
        }
        super.motionEnded(motion, with: event)
    }
}
