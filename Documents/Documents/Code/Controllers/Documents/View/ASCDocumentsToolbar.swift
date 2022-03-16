//
//  ASCDocumentsToolbar.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCDocumentsToolbar: UIToolbar {
    override func layoutSubviews() {
        super.layoutSubviews()

        if let uiBarBackground = subviews.first(where: { NSStringFromClass($0.classForCoder).contains("UIBarBackground") }),
           let uiToolbarContentView = subviews.first(where: { NSStringFromClass($0.classForCoder).contains("UIToolbarContentView") })
        {
            let contentViewHeight = uiToolbarContentView.frame.height

            if (uiBarBackground.height - contentViewHeight) < contentViewHeight {
                return
            }

            uiBarBackground.frame = CGRect(
                x: uiBarBackground.x,
                y: uiBarBackground.y + contentViewHeight,
                width: uiBarBackground.width,
                height: uiBarBackground.height - contentViewHeight
            )

            uiToolbarContentView.frame = CGRect(
                x: uiToolbarContentView.x,
                y: uiToolbarContentView.y + contentViewHeight,
                width: uiToolbarContentView.width,
                height: uiToolbarContentView.height
            )
        }
    }
}
