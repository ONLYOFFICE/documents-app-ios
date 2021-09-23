//
//  UITextField+Style.swift
//  Documents
//
//  Created by Alexander Yuzhin on 12.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UITextField {
    
    var textStyle: ASCTextStyle {
       
        get {
            ASCTextStyle.undefined
        }
       
        set(newValue) {
            self.font = newValue.font
            self.textColor = newValue.color
        }
    }
    
    var placeholderTextStyle: ASCTextStyle {
       
        get {
            ASCTextStyle.undefined
        }
       
        set(newValue) {
            self.attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [
                .font : newValue.font,
                .foregroundColor : newValue.color
            ])
        }
    }
}
