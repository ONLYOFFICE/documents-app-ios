//
//  ASCIntroPageController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/2/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCIntroPageController: UIViewController {
    static let identifier = String(describing: ASCIntroPageController.self)

    // MARK: - Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var imageHeightConstarin: NSLayoutConstraint!
    
    
    // MARK: - Properties
    
    var page: ASCIntroPage? {
        didSet {
            updateView()
        }
    }
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func updateView() {
        guard let page = page else { return }
        
        imageView?.image = page.image
        titleLabel?.text = page.title
        infoLabel?.text = page.subtitle
    }

}
