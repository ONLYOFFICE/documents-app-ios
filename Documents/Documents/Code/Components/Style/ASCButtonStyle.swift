//
//  ASCButtonStyle.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ASCButtonStyleType: Int {
    case `default`, action, blank, bordered, gray, capsule, link
}

class ASCButtonStyle: UIButton {
    // MARK: - Properties

    var styleType: ASCButtonStyleType = .default {
        didSet {
            updateStyle()
        }
    }

    @IBInspectable
    var styleTypeAdapter: Int {
        get {
            return styleType.rawValue
        }
        set(styleIndex) {
            styleType = ASCButtonStyleType(rawValue: styleIndex) ?? .default
        }
    }

    override open var isHighlighted: Bool {
        didSet {
            switch styleType {
            case .action:
                if #available(iOS 26.0, *) {
                    //
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
                        self.backgroundColor = self.isHighlighted
                            ? Asset.Colors.action.color.lighten()
                            : Asset.Colors.action.color
                        self.backgroundColor = self.isEnabled
                            ? self.backgroundColor
                            : .lightGray
                    }, completion: nil)
                    setTitleColorForAllStates(.white)
                }

            case .bordered:
                if #available(iOS 26.0, *) {
                    //
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
                        self.backgroundColor = self.isHighlighted
                            ? .lightGray.lighten(by: 0.3)
                            : .clear
                        self.layer.borderColor = self.isHighlighted
                            ? UIColor.gray.lighten(by: 0.3).cgColor
                            : UIColor.gray.cgColor
                        self.backgroundColor = self.isEnabled
                            ? self.backgroundColor
                            : .lightGray
                    }, completion: nil)
                    setTitleColorForAllStates(.gray)
                }

            case .gray:
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
                    self.backgroundColor = self.isEnabled
                        ? self.backgroundColor
                        : .lightGray
                }, completion: nil)
                if #available(iOS 13.0, *) {
                    setTitleColorForAllStates(.label)
                } else {
                    setTitleColorForAllStates(.black)
                }

            case .blank:
                if #available(iOS 26.0, *) {
                    //
                } else {
                    var isDark = false
                    var bgColor: UIColor = .white
                    if #available(iOS 13.0, *) {
                        isDark = traitCollection.userInterfaceStyle == .dark
                        bgColor = UIColor(light: .white, dark: .systemGray5)
                    }
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
                        self.backgroundColor = self.isHighlighted
                            ? isDark ? bgColor.lighten(by: 0.1) : bgColor.darken(by: 0.1)
                            : bgColor
                    }, completion: nil)
                }
                setTitleColorForAllStates(Asset.Colors.brend.color)

            case .capsule:
                if #available(iOS 26.0, *) {
                    //
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
                        self.backgroundColor = self.isHighlighted
                            ? Asset.Colors.brend.color.lighten()
                            : Asset.Colors.brend.color
                        self.backgroundColor = self.isEnabled
                            ? self.backgroundColor
                            : .lightGray
                    }, completion: nil)
                }

            case .link:
                backgroundColor = .clear
                setTitleColorForAllStates(
                    isHighlighted
                        ? .systemBlue.lighten(by: 0.1)
                        : .systemBlue
                )

            default:
                if #available(iOS 26.0, *) {
                    //
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
                        self.backgroundColor = self.isHighlighted
                            ? Asset.Colors.brend.color.lighten()
                            : Asset.Colors.brend.color
                        self.backgroundColor = self.isEnabled
                            ? self.backgroundColor
                            : .lightGray
                        self.titleLabel?.textAlignment = .center
                        self.titleLabel?.transform = self.isHighlighted
                            ? CGAffineTransform(scaleX: 0.92, y: 0.92)
                            : .identity
                    }, completion: nil)
                }
            }
        }
    }

    override open var isEnabled: Bool {
        didSet {
            switch styleType {
            case .action:
                if #available(iOS 26.0, *) {
                    //
                } else {
                    backgroundColor = isEnabled ? Asset.Colors.action.color : Asset.Colors.grayLight.color
                }

            case .blank:
                if #available(iOS 26.0, *) {
                    //
                } else {
                    backgroundColor = isEnabled ? UIColor(light: .white, dark: .systemGray5) : Asset.Colors.grayLight.color
                }

            case .bordered:
                backgroundColor = isEnabled ? .clear : .lightGray.lighten()

            case .gray:
                backgroundColor = isEnabled ? .lightGray.lighten(by: 0.5) : .lightGray.lighten(by: 0.7)

            case .link:
                backgroundColor = .clear
                setTitleColorForAllStates(
                    isEnabled
                        ? .systemBlue
                        : .lightGray.lighten(by: 0.5)
                )

            default:
                if #available(iOS 26.0, *) {
                    //
                } else {
                    backgroundColor = isEnabled ? Asset.Colors.brend.color : Asset.Colors.grayLight.color
                }
            }
        }
    }

    // MARK: - Lifecycle Methods

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        switch styleType {
        case .capsule:
            layerCornerRadius = height * 0.5

        default:
            if #available(iOS 26.0, *) {
                layerCornerRadius = height * 0.5
            }
        }
    }

    private func updateStyle() {
        switch styleType {
        case .action:
            backgroundColor = Asset.Colors.action.color
            titleLabel?.textStyle = ASCTextStyle.subheadlineWhite
            titleLabel?.adjustsFontForContentSizeCategory = true
            if #available(iOS 26.0, *) {
                configuration = .prominentGlass()
            } else {
                layer.cornerRadius = 8
                layer.shadowOpacity = 1
                layer.shadowColor = UIColor.lightGray.cgColor
                layer.shadowOffset = CGSize(width: 0, height: 1)
                // layer.shouldRasterize = true
                layer.shadowRadius = 1
            }

        case .blank:
            if #available(iOS 26.0, *) {
                configuration = .clearGlass()
            } else {
                backgroundColor = UIColor(light: .white, dark: .systemGray5)
                layer.cornerRadius = 8
            }
            titleLabel?.adjustsFontForContentSizeCategory = true
            setTitleColorForAllStates(Asset.Colors.brend.color)

        case .bordered:
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = UIColor.gray.cgColor
            titleLabel?.textStyle = ASCTextStyle.bodyWhite
            titleLabel?.textColor = .gray
            layerCornerRadius = 8.0

        case .gray:
            layerCornerRadius = 8.0

        case .capsule:
            backgroundColor = Asset.Colors.brend.color
            titleLabel?.textStyle = ASCTextStyle.subheadlineBold
            titleLabel?.adjustsFontForContentSizeCategory = true
            contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
            layerCornerRadius = height * 0.5
            if #available(iOS 26.0, *) {
                configuration = .prominentGlass()
            }

        case .link:
            backgroundColor = .clear
            setTitleColorForAllStates(.systemBlue)

        default:
            backgroundColor = Asset.Colors.brend.color
            titleLabel?.textStyle = ASCTextStyle.bodyWhite
            titleLabel?.adjustsFontForContentSizeCategory = true
            layerCornerRadius = 8.0
            if #available(iOS 26.0, *) {
                configuration = .prominentGlass()
            }
        }

        /// Update disabled
        let enabled = isEnabled
        isEnabled = enabled
    }

    private func updateColors() {
        //
    }
}
