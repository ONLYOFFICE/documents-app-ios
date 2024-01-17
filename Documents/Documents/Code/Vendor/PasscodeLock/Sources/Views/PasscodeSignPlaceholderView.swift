//
//  PasscodeSignPlaceholderView.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

#if os(iOS)

import UIKit

@IBDesignable
open class PasscodeSignPlaceholderView: UIView {
    public enum State {
        case inactive
        case active
        case error
    }

    @IBInspectable
    open var inactiveColor: UIColor = PasscodeLockStyles.SignPlaceholderViewStyles.inactiveColor {
        didSet {
            setupView()
        }
    }

    @IBInspectable
    open var activeColor: UIColor = PasscodeLockStyles.SignPlaceholderViewStyles.activeColor {
        didSet {
            setupView()
        }
    }

    @IBInspectable
    open var errorColor: UIColor = PasscodeLockStyles.SignPlaceholderViewStyles.errorColor {
        didSet {
            setupView()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    override open var intrinsicContentSize: CGSize {
        return CGSize(width: 14, height: 14)
    }

    fileprivate func setupView() {
        layer.cornerRadius = 7
        layer.borderWidth = 1
        layer.borderColor = activeColor.cgColor
        backgroundColor = inactiveColor
    }

    fileprivate func colorsForState(_ state: State) -> (backgroundColor: UIColor, borderColor: UIColor) {
        switch state {
        case .inactive: return (inactiveColor, activeColor)
        case .active: return (activeColor, activeColor)
        case .error: return (errorColor, errorColor)
        }
    }

    open func animateState(_ state: State) {
        let colors = colorsForState(state)

        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                self.backgroundColor = colors.backgroundColor
                self.layer.borderColor = colors.borderColor.cgColor

            },
            completion: nil
        )
    }
}

#endif
