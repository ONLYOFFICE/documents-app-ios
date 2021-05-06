//
//  ASCTextStyle.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//


import UIKit

enum ASCTextStyle {
    
    // MARK: - Buttons
    
    case bodyFontWhite
    case subheadFontWhite
    case subheadBold

    // MARK: - signature
    
    case undefined
    
    var style: (font: UIFont, color: UIColor, lineHeightMultiple: CGFloat) {
        switch self {
        
        // MARK: - Buttons

        case .bodyFontWhite:
            return (UIFont.preferredFont(forTextStyle: .body), .white, 1)
            
        case .subheadFontWhite:
            return (UIFont.preferredFont(forTextStyle: .subheadline), .white, 1)
            
        case .subheadBold:
            if #available(iOS 13.0, *) {
                return (UIFont.preferredFont(forTextStyle: .subheadline).bold(), .label, 1)
            } else {
                return (UIFont.preferredFont(forTextStyle: .subheadline).bold(), .black, 1)
            }
            
        // MARK: - signature
        
        case .undefined:
            return (UIFont(), .clear, 1.0)
        }
    }
    
    var font: UIFont {
        return self.style.font
    }
    
    var color: UIColor {
        return self.style.color
    }
    
    var lineHeightMultiple: CGFloat {
        return self.style.lineHeightMultiple
    }
}
