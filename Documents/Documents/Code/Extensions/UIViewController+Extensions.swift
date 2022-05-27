//
//  UIViewController+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 07/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

// MARK: - Properties

public extension UIViewController {
    /// Check if ViewController is onscreen and not hidden.
    var isVisible: Bool {
        // http://stackoverflow.com/questions/2777438/how-to-tell-if-uiviewcontrollers-view-is-visible
        return isViewLoaded && view.window != nil
    }
}

// MARK: - Methods

extension UIViewController {
    /// Assign as listener to notification.
    ///
    /// - Parameters:
    ///   - name: notification name.
    ///   - selector: selector to run with notified.
    func addNotificationObserver(name: Notification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }

    /// Unassign as listener to notification.
    ///
    /// - Parameter name: notification name.
    func removeNotificationObserver(name: Notification.Name) {
        NotificationCenter.default.removeObserver(self, name: name, object: nil)
    }

    /// Unassign as listener from all notifications.
    func removeNotificationsObserver() {
        NotificationCenter.default.removeObserver(self)
    }

    /// Type-safe method to instantiate a viewcontroller from storyboard
    class func instantiateFromStoryboard(storyboardName: String) -> Self {
        return instantiateFromStoryboardHelper(type: self, storyboardName: storyboardName)
    }

    /// Type-safe method to instantiate a viewcontroller from storyboard
    class func instantiate(from storyboard: Storyboard) -> Self {
        return instantiateFromStoryboardHelper(type: self, storyboardName: storyboard.rawValue)
    }

    /// Internal Type-safe method to instantiate a viewcontroller from storyboard
    private class func instantiateFromStoryboardHelper<T>(type: T.Type, storyboardName: String) -> T {
        let storyboardId = String(describing: T.self).components(separatedBy: ".").last

        let storyboad = UIStoryboard(name: storyboardName, bundle: nil)
        let controller = storyboad.instantiateViewController(withIdentifier: storyboardId!) as! T

        return controller
    }

    /// Top most ViewController
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }

        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }

        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }

        if let split = self as? UISplitViewController {
            return split.viewControllers.last?.topMostViewController() ?? split
        }

        return self
    }

    /// Update large titles area if needed
    func updateLargeTitlesSize() {
        guard
            let navigationController = navigationController,
            navigationController.navigationBar.prefersLargeTitles
        else { return }

        navigationController.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        navigationController.navigationBar.sizeToFit()
    }

    /// Search parent
    func findParentController<T: UIViewController>() -> T? {
        return self is T ? self as? T : parent?.findParentController() as T?
    }

    /// Hide keyboard when tapped around
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    /// Check status of notifications and registry if needed
    public func checkNotifications(complation: ((UNAuthorizationStatus) -> Void)?) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                complation?(settings.authorizationStatus)
            }
        }
    }
}
