//
//  ASCBaseViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/19/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCBaseViewController: UIViewController {

    // MARK: - Properties
    
    lazy var navigator = ASCNavigator(navigationController: navigationController)
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
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
    
    // MARK: - Helpers
    
    func popControllers(_ count: Int = 1) {
        let shift = count + 1
        if let viewControllers = self.navigationController?.viewControllers {
            guard viewControllers.count < shift else {
                self.navigationController?.popToViewController(viewControllers[viewControllers.count - shift], animated: true)
                return
            }
        }
    }
}
