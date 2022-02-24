//
//  UIStoryboard+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

// MARK: - Methods

extension UIStoryboard {
    /// Get main storyboard for application
    static var main: UIStoryboard? {
        let bundle = Bundle.main
        guard let name = bundle.object(forInfoDictionaryKey: "UIMainStoryboardFile") as? String else { return nil }
        return UIStoryboard(name: name, bundle: bundle)
    }

    /// Instantiate a UIViewController using its class name
    ///
    /// - Parameter name: UIViewController type
    /// - Returns: The view controller corresponding to specified class name
    func instantiateViewController<T: UIViewController>(withClass name: T.Type) -> T? {
        return instantiateViewController(withIdentifier: String(describing: name)) as? T
    }

    ///
    /// Create new `ViewController` from `Storyboard`.
    /// - Parameter storyboard: The storyboard to instantiate the view controller from.
    /// - Parameter controller: The view controller type that you want to instantiate.
    /// - Parameter bundle: The bundle containing the storyboard file and its resources.
    /// Default value is `Bundle.main`.
    ///
    /// - Returns: A view controller instance.
    ///
    static func create<T>(storyboard: Storyboard,
                          controller: T.Type,
                          bundle: Bundle? = Bundle.main) -> T
    {
        let uiStoryboard = UIStoryboard(name: storyboard.rawValue, bundle: nil)
        return uiStoryboard.instantiateViewController(withIdentifier: String(describing: controller.self)) as! T
    }
}

///
/// Storyboards used in the app, when you create new `Storyboard` you need to add it here
/// to use it.
///
enum Storyboard: String {
    case launchScreen, main, login, sort, transfer, intro, connectStorage,
         settings, userProfile, createPortal, debug

    var rawValue: String {
        switch self {
        case .launchScreen:
            return StoryboardScene.LaunchScreen.storyboardName
        case .main:
            return StoryboardScene.Main.storyboardName
        case .login:
            return StoryboardScene.Login.storyboardName
        case .sort:
            return StoryboardScene.Sort.storyboardName
        case .transfer:
            return StoryboardScene.Transfer.storyboardName
        case .intro:
            return StoryboardScene.Intro.storyboardName
        case .connectStorage:
            return StoryboardScene.ConnectStorage.storyboardName
        case .settings:
            return StoryboardScene.Settings.storyboardName
        case .userProfile:
            return StoryboardScene.UserProfile.storyboardName
        case .createPortal:
            return StoryboardScene.CreatePortal.storyboardName
        case .debug:
            return StoryboardScene.Debug.storyboardName
        }
    }
}
