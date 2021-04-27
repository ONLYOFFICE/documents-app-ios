//
//  UILabel+Style.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UILabel {
    
    var textStyle: ASCTextStyle {
       
        get {
            ASCTextStyle.undefined
        }
       
        set(newValue) {
            self.font = newValue.font
            self.textColor = newValue.color
        }
    }
}
