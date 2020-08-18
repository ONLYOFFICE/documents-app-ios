//
//  ASCUserAvatarView.swift
//  Projects
//
//  Created by Alexander Yuzhin on 2/5/18.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCUserAvatarView: UIImageView {

    // MARK: - Properties

    lazy private var innerBorder: CAShapeLayer = {
        $0.strokeColor = UIColor.lightGray.withAlphaComponent(0.1).cgColor
        $0.lineWidth = 2
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
        layer.addSublayer(innerBorder)
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        layer.cornerRadius = bounds.width * 0.5
        innerBorder.path = UIBezierPath(ovalIn: bounds).cgPath
        innerBorder.frame = bounds
    }
}
