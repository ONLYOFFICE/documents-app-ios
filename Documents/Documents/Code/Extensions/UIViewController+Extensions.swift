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

    /// Helper method to display an alert on any UIViewController subclass. Uses UIAlertController to show an alert
    ///
    /// - Parameters:
    ///   - title: title of the alert
    ///   - message: message/body of the alert
    ///   - buttonTitles: (Optional)list of button titles for the alert. Default button i.e "OK" will be shown if this paramter is nil
    ///   - highlightedButtonIndex: (Optional) index of the button from buttonTitles that should be highlighted. If this parameter is nil no button will be highlighted
    ///   - completion: (Optional) completion block to be invoked when any one of the buttons is tapped. It passes the index of the tapped button as an argument
    /// - Returns: UIAlertController object (discardable).
    @discardableResult
    func showAlert(
        title: String?,
        message: String?,
        buttonTitles: [String]? = nil,
        highlightedButtonIndex: Int? = nil,
        completion: ((Int) -> Void)? = nil
    ) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var allButtons = buttonTitles ?? [String]()
        if allButtons.count == 0 {
            allButtons.append("OK")
        }

        for index in 0 ..< allButtons.count {
            let buttonTitle = allButtons[index]
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: { _ in
                completion?(index)
            })
            alertController.addAction(action)
            // Check which button to highlight
            if let highlightedButtonIndex = highlightedButtonIndex, index == highlightedButtonIndex {
                alertController.preferredAction = action
            }
        }
        present(alertController, animated: true, completion: nil)
        return alertController
    }
}
