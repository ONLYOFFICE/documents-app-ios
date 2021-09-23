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
        border.tag = 0x5F3759DF
        border.backgroundColor = color
        border.frame = CGRect(x: 0,
                              y: frame.size.height - weight,
                              width: frame.size.width,
                              height: weight)
        border.autoresizingMask = [.flexibleWidth]
        
        if let borederView = subviews.first(where: { $0.tag == 0x5F3759DF }) {
            borederView.removeFromSuperview()
        }
        addSubview(border)
    }

}
