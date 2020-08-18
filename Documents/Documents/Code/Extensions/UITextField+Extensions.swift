//
//  UITextField+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 16/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UITextField {

    func underline(color: UIColor = .black, weight: CGFloat = 1.0 / UIScreen.main.scale) {
        let border = UIView()
        border.backgroundColor = color
        border.frame = CGRect(x: 0,
                              y: frame.size.height - weight,
                              width: frame.size.width,
                              height: weight)
        border.autoresizingMask = [.flexibleWidth]
        addSubview(border)
    }

}
