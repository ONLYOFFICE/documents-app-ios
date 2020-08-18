//
//  NSLayoutConstraint+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/15/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    
    @IBInspectable
    var preciseConstant: Int {
        get {
            return Int(constant * UIScreen.main.scale)
        }
        set {
            constant = CGFloat(newValue) / UIScreen.main.scale
        }
    }
}
