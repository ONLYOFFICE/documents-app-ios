//
//  PasscodeSignButton.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

#if os(iOS)

    import UIKit

    @IBDesignable
    open class PasscodeSignButton: UIButton {
        @IBInspectable
        open var passcodeSign: String = "1"

        @IBInspectable
        open var borderColor: UIColor = PasscodeLockStyles.SignButtonStyles.borderColor {
            didSet {
                setupView()
            }
        }

        @IBInspectable
        open var borderRadius: CGFloat = 35 {
            didSet {
                setupView()
            }
        }

        @IBInspectable
        open var highlightBackgroundColor: UIColor = PasscodeLockStyles.SignButtonStyles.highlightBackgroundColor {
            didSet {
                setupView()
            }
        }

        override public init(frame: CGRect) {
            super.init(frame: frame)

            setupView()
            setupActions()
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)

            setupView()
            setupActions()
        }

        override open var intrinsicContentSize: CGSize {
            return CGSize(width: 70, height: 70)
        }

        fileprivate var defaultBackgroundColor = UIColor.clear

        fileprivate func setupView() {
            if #available(iOS 26.0, *) {
                configuration = .glass()
            } else {
                layer.borderWidth = 1
                layer.cornerRadius = borderRadius
                layer.borderColor = borderColor.cgColor

                setTitleColor(PasscodeLockStyles.SignButtonStyles.textColor, for: .normal)

                if let backgroundColor = backgroundColor {
                    defaultBackgroundColor = backgroundColor
                }
            }
        }

        fileprivate func setupActions() {
            addTarget(self, action: #selector(PasscodeSignButton.handleTouchDown), for: .touchDown)
            addTarget(self, action: #selector(PasscodeSignButton.handleTouchUp), for: [.touchUpInside, .touchDragOutside, .touchCancel])
        }

        @objc func handleTouchDown() {
            animateBackgroundColor(highlightBackgroundColor)
        }

        @objc func handleTouchUp() {
            animateBackgroundColor(defaultBackgroundColor)
        }

        fileprivate func animateBackgroundColor(_ color: UIColor) {
            UIView.animate(
                withDuration: 0.3,
                delay: 0.0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: 0.0,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: {
                    self.backgroundColor = color
                },
                completion: nil
            )
        }
    }

#endif
