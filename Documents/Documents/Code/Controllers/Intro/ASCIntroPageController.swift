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

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var imageHeightConstarin: NSLayoutConstraint!
    
    var pageImage: UIImage?
    var pageTitle: String?
    var pageInfo: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = pageImage {
            imageView?.image = image
        }
        
        if let title = pageTitle {
            titleLabel?.text = title
        }
        
        if let info = pageInfo {
            infoLabel?.text = info
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
