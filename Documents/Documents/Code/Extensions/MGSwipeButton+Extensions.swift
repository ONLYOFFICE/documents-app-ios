//
//  MGSwipeButton+Extensions.swift
//  R7-Office
//
//  Created by Alexander Yuzhin on 25/09/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import MGSwipeTableCell

extension MGSwipeButton {
    func horizontalCenterIconOverText(spacing: CGFloat = 3) {
        guard
            let titleLabel = titleLabel,
            let image = imageView?.image
        else { return }

        let imageSize = image.size

//        contentEdgeInsets = .zero

        titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageSize.width,
            bottom: -(imageSize.height + spacing),
            right: 0
        )

        layoutSubviews()

        imageEdgeInsets = UIEdgeInsets(
            top: -(titleLabel.height + spacing),
            left: 0,
            bottom: 0,
            right: -titleLabel.width
        )
    }
}
