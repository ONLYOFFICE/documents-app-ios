//
//  ASCBaseTableViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 21.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCBaseTableViewController: UITableViewController {
    // MARK: - Properties

    lazy var navigator = ASCNavigator(navigationController: navigationController)

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.tintColor = Asset.Colors.brend.color

        if !ASCAppSettings.Feature.allowLargeTitle {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return super.preferredInterfaceOrientationForPresentation
    }

    // MARK: - Create

    class var storyboard: Storyboard {
        fatalError("Storyboard not defined:\(String(describing: self))")
    }

    class func instance() -> Self {
        return instantiate(from: storyboard)
    }
}
