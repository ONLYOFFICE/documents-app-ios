//
//  ASCRightAlignedCollectionViewFlowLayout.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCRightAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)

        var rightMargin = sectionInset.right
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttribute in
            guard layoutAttribute.representedElementCategory == .cell else {
                return
            }
            if layoutAttribute.frame.origin.y >= maxY {
                rightMargin = sectionInset.right
            }

            layoutAttribute.frame.origin.x = rect.width - rightMargin - layoutAttribute.frame.width - minimumInteritemSpacing

            rightMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }

        return attributes
    }
}
