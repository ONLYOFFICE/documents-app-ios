//
//  ASCProfileAvatarView.swift
//  Documents
//
//  Created by Alexander Yuzhin on 24/06/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCProfileAvatarView: UIImageView {

    // MARK: - Properties

    lazy private var innerBorderLayer: CAShapeLayer = {
        $0.strokeColor = UIColor.white.cgColor
        $0.lineWidth = 4
        $0.frame = bounds
        $0.fillColor = nil
        $0.path = UIBezierPath(ovalIn: bounds).cgPath
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
        layer.cornerRadius = bounds.width * 0.5
        layer.masksToBounds = true
        layer.addSublayer(innerBorderLayer)

        backgroundColor = .groupTableViewBackground
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        layer.cornerRadius = bounds.width * 0.5
        innerBorderLayer.path = UIBezierPath(ovalIn: bounds).cgPath
        innerBorderLayer.frame = bounds
    }
}
