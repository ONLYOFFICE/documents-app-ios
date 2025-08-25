//
//  ASCBaseNavigationController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/19/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCBaseNavigationController: UINavigationController {
    // MARK: - Properties

    var hasShadow: Bool = false {
        didSet {
            if oldValue != hasShadow {
                if hasShadow {
                    view.clipsToBounds = false

                    let localShadowView = UIView(frame: CGRect(x: view.frame.width - 0.5, y: 0, width: 0.5, height: view.frame.height))
                    localShadowView.backgroundColor = Asset.Colors.tableCellSeparator.color
                    localShadowView.autoresizingMask = [.flexibleLeftMargin, .flexibleHeight]
                    view.addSubview(localShadowView)

                    shadowView = localShadowView
                } else {
                    shadowView?.removeFromSuperview()
                    shadowView = nil
                }
            }
        }
    }

    private var shadowView: UIView?

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = Asset.Colors.brend.color
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return topViewController?.preferredInterfaceOrientationForPresentation ?? super.preferredInterfaceOrientationForPresentation
    }

    // MARK: - UI

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        shadowView?.backgroundColor = Asset.Colors.tableCellSeparator.color
    }

    // MARK: - Methods for change style status bar

    override open var childForStatusBarStyle: UIViewController? {
        return topViewController
    }

    override open var childForStatusBarHidden: UIViewController? {
        return topViewController
    }
}
