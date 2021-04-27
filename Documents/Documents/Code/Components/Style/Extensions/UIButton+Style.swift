//
//  UIButton+Style.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UIButton {
    
    var textStyle: ASCTextStyle {
        
        get {
            ASCTextStyle.undefined
        }
        
        set(newValue) {
            self.titleLabel?.font = newValue.font
            self.setTitleColor(newValue.color, for: .normal)
        }
    }

    var textStyleSelected: ASCTextStyle {
        
        get {
            ASCTextStyle.undefined
        }
        
        set(newValue) {
            self.titleLabel?.font = newValue.font
            self.setTitleColor(newValue.color, for: .selected)
        }
    }
    
    var textStyleDisabled: ASCTextStyle {
        
        get {
            ASCTextStyle.undefined
        }
        
        set(newValue) {
            self.titleLabel?.font = newValue.font
            self.setTitleColor(newValue.color, for: .disabled)
        }
    }
}
