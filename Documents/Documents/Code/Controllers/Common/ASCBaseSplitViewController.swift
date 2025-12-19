//
//  ASCBaseSplitViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCBaseSplitViewController: UISplitViewController {
    // MARK: - Properties

    var primaryViewController: UIViewController? {
        return viewControllers.first
    }

    var detailViewController: UIViewController? {
        return viewControllers.count > 1 ? viewControllers[1] : nil
    }

    private var isDidAppear: Bool = false

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.tintColor = Asset.Colors.brend.color

        delegate = self

        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white

        if !ASCCommon.isiOS26 {
            if let navigationController = viewControllers.last as? UINavigationController {
                navigationController.topViewController?.navigationItem.leftBarButtonItem = displayModeButtonItem
                navigationController.topViewController?.navigationItem.leftItemsSupplementBackButton = UIDevice.pad
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        isDidAppear = true
        super.viewDidAppear(animated)
    }

    // MARK: - UI

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
    }
}

extension ASCBaseSplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController,
                             willChangeTo displayMode: UISplitViewController.DisplayMode)
    {
        if let detailView = svc.viewControllers.first as? UINavigationController {
            svc.navigationItem.backBarButtonItem = nil
            detailView.topViewController?.navigationItem.leftBarButtonItem = nil
        }
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool
    {
        if UIDevice.phone {
            if let primaryNC = primaryViewController as? UINavigationController {
                if let topVC = ASCViewControllerManager.shared.rootController?.topMostViewController() {
                    if topVC.description.contains("VNDocumentCameraViewController") {
                        return false
                    }
                }

                primaryNC.popToRootViewController(animated: false)
                return true
            }
        }
        return false
    }

    // https://forums.developer.apple.com/thread/88774
    func splitViewController(_ splitViewController: UISplitViewController,
                             showDetail vc: UIViewController,
                             sender: Any?) -> Bool
    {
        if UIDevice.phone, let navController = vc as? UINavigationController {
            if isDidAppear {
                if splitViewController.isCollapsed {
                    if let detailVC = navController.topViewController {
                        splitViewController.showDetailViewController(detailVC, sender: sender)
                        return true
                    }
                }
            } else {
                if let detailVC = navController.topViewController {
                    splitViewController.showDetailViewController(detailVC, sender: sender)
                    return true
                }
            }
        }
        return false
    }
}
