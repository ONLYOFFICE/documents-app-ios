//
//  ASCShadowRadiusView.swift
//  Documents
//
//  Created by Alexander Yuzhin on 24/06/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCShadowRadiusView: UIView {

    // MARK: - Properties

    @IBInspectable var shadowColor: UIColor = .gray
    @IBInspectable var shadowOffset: CGSize = CGSize(width: 0, height: 2)
    @IBInspectable var shadowRadius: CGFloat = 3
    @IBInspectable var shadowOpacity: Float = 0.25

    lazy private var shadowLayer: CAShapeLayer = {
        $0.shadowColor = shadowColor.cgColor
        $0.shadowOffset = shadowOffset
        $0.shadowRadius = shadowRadius
        $0.shadowOpacity = shadowOpacity
        $0.masksToBounds = false
        return $0
    }(CAShapeLayer())

    // MARK: - Lifecycle Methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        layer.addSublayer(shadowLayer)
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        shadowLayer.path = UIBezierPath(ovalIn: CGRect(
            x: bounds.origin.x + 1,
            y: bounds.origin.y + 1,
            width: bounds.width - 2,
            height: bounds.height - 2)).cgPath
    }

}
