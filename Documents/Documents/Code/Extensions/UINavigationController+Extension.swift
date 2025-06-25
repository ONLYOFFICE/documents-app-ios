//
//  UINavigationController+Extension.swift
//  Documents
//
//  Created by Alexey Musinov on 15.06.17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
    convenience init(rootASCViewController: UIViewController) {
        self.init(rootViewController: rootASCViewController)

        view.tintColor = Asset.Colors.brend.color

        navigationBar.prefersLargeTitles = ASCAppSettings.Feature.allowLargeTitle
        rootASCViewController.navigationItem.largeTitleDisplayMode = .automatic

        modalPresentationStyle = .formSheet
    }

    public func pushViewController(_ viewController: UIViewController,
                                   animated: Bool,
                                   completion: @escaping () -> Void)
    {
        pushViewController(viewController, animated: animated)

        guard animated, let coordinator = transitionCoordinator else {
            completion()
            return
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }
}
