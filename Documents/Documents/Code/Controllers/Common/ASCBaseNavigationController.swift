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
                    localShadowView.backgroundColor = UIColor(named: "table-cell-separator")
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? [.portrait, .landscape]
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return topViewController?.preferredInterfaceOrientationForPresentation ?? super.preferredInterfaceOrientationForPresentation
    }
}
