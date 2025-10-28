//
//  ASCPaddingLabel.swift
//  Documents
//
//  Created by Alexander Yuzhin on 02.08.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

@IBDesignable class ASCPaddingLabel: UILabel {
    @IBInspectable var topInset: CGFloat = 1.0
    @IBInspectable var bottomInset: CGFloat = 1.0
    @IBInspectable var leftInset: CGFloat = 1.0
    @IBInspectable var rightInset: CGFloat = 1.0

    var padding: UIEdgeInsets? {
        get {
            return UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        }
        set {
            topInset = newValue?.top ?? 0
            bottomInset = newValue?.bottom ?? 0
            leftInset = newValue?.left ?? 0
            rightInset = newValue?.right ?? 0
            invalidateIntrinsicContentSize()
            sizeToFit()
        }
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let textRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -topInset,
                                          left: -leftInset,
                                          bottom: -bottomInset,
                                          right: -rightInset)
        return textRect.inset(by: invertedInsets)
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }

//    override var bounds: CGRect {
//        didSet {
//            // ensures this works within stack views if multi-line
//            preferredMaxLayoutWidth = bounds.width - (leftInset + rightInset)
//        }
//    }
}
