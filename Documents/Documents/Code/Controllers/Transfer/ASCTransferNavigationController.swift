//
//  ASCTransferNavigationController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 4/14/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

// enum ASCTransferMode: Int {
//    case local
//    case cloud
// }

enum ASCTransferType: Int {
    case copy
    case move
    case recover
    case select
}

class ASCTransferNavigationController: ASCBaseNavigationController {
    static let identifier = String(describing: ASCTransferNavigationController.self)

    var transferType: ASCTransferType = .copy
    var sourceProvider: ASCFileProviderProtocol?
    var sourceFolder: ASCFolder?
    var sourceItems: [ASCEntity]?
    var doneHandler: ((ASCFileProviderProtocol?, ASCFolder?, String?) -> Void)?
    var displayActionButtonOnRootVC: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateToolBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)

        updateToolBar()
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let viewcontroller = super.popViewController(animated: animated)

        updateToolBar()

        return viewcontroller
    }
    
    private func updateToolBar() {
        setToolbarHidden(viewControllers.count < 2 && !displayActionButtonOnRootVC, animated: true)
    }
}
