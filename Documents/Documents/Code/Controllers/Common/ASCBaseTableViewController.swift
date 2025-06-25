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

    public class var storyboard: Storyboard {
        fatalError("Storyboard not defined:\(String(describing: self))")
    }

    public class func instance() -> Self {
        return instantiate(from: storyboard)
    }
}
