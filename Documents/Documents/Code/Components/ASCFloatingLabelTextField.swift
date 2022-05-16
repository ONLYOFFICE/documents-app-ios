//
//  ASCFloatingLabelTextField.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.02.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import SkyFloatingLabelTextField
import UIKit

class ASCFloatingLabelTextField: SkyFloatingLabelTextField {
    // MARK: - Properties

    @IBInspectable var leftPadding: CGFloat = 0
    @IBInspectable var rightPadding: CGFloat = 0

    // MARK: - Lifecycle Methods

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: leftPadding,
            y: titleHeight(),
            width: bounds.size.width - rightPadding,
            height: bounds.size.height - titleHeight() - selectedLineHeight
        )
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: leftPadding,
            y: titleHeight(),
            width: bounds.size.width - rightPadding,
            height: bounds.size.height - titleHeight() - selectedLineHeight
        )
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: leftPadding,
            y: titleHeight(),
            width: bounds.size.width - rightPadding,
            height: bounds.size.height - titleHeight() - selectedLineHeight
        )
    }

    override func titleLabelRectForBounds(_ bounds: CGRect, editing: Bool) -> CGRect {
        if editing {
            return CGRect(x: leftPadding, y: 5, width: bounds.size.width, height: titleHeight())
        }
        return CGRect(x: leftPadding, y: titleHeight(), width: bounds.size.width, height: titleHeight())
    }
}
