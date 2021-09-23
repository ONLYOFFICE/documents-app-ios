//
//  ASCButtonStyle.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ASCButtonStyleType: Int {
    case `default`, action
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
        set (styleIndex) {
            styleType = ASCButtonStyleType(rawValue: styleIndex) ?? .default
        }
    }

    open override var isHighlighted: Bool {
        didSet {
            switch styleType {
            case .action:
                UIView.animate(withDuration: 0.2, delay: 0.0, options:[], animations: {
                    self.backgroundColor = self.isHighlighted
                        ? Asset.Colors.action.color.lighten()
                        : Asset.Colors.action.color
                    self.backgroundColor = self.isEnabled
                        ? self.backgroundColor
                        : .lightGray
                }, completion:nil)
                setTitleColorForAllStates(.white)
            default:
                UIView.animate(withDuration: 0.2, delay: 0.0, options:[], animations: {
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
                }, completion:nil)
            }
        }
    }

    open override var isEnabled: Bool {
        didSet {
            switch styleType {
            case .action:
                backgroundColor = isEnabled ? Asset.Colors.action.color : Asset.Colors.grayLight.color
            default:
                backgroundColor = isEnabled ? Asset.Colors.brend.color : Asset.Colors.grayLight.color
            }
        }
    }

    // MARK: - Lifecycle Methods

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateColors()
    }

    private func updateStyle() {
        switch styleType {
        case .action:
            backgroundColor = Asset.Colors.action.color
            titleLabel?.textStyle = ASCTextStyle.subheadWhite
            titleLabel?.adjustsFontForContentSizeCategory = true
            layer.cornerRadius = 8
            layer.shadowOpacity = 1
            layer.shadowColor = UIColor.lightGray.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 1)
            // layer.shouldRasterize = true
            layer.shadowRadius = 1
            
        default:
            backgroundColor = Asset.Colors.brend.color
            titleLabel?.textStyle = ASCTextStyle.bodyWhite
            titleLabel?.adjustsFontForContentSizeCategory = true
            layerCornerRadius = 8.0
        }

        /// Update disabled
        let enabled = isEnabled
        self.isEnabled = enabled
    }

    private func updateColors() {
        //
    }

}
