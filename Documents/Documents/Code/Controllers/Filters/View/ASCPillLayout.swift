//
//  ASCPillLayout.swift
//  Documents
//
//  Created by Лолита Чернышева on 31.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCPillLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, sizeForPillAtIndexPath indexPath: IndexPath) -> CGSize
    func collectionView(_ collectionView: UICollectionView, heightForHeaderInSection section: Int) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, insetsForItemsInSection section: Int) -> UIEdgeInsets
    func collectionView(_ collectionView: UICollectionView, itemSpacingInSection section: Int) -> CGFloat
}

class ASCPillLayout: UICollectionViewLayout {
    weak var delegate: ASCPillLayoutDelegate?

    // Total height of the content. Will be used to configure the scrollview content
    var layoutHeight: CGFloat = 0.0

    private var headerCache: [UICollectionViewLayoutAttributes] = []
    private var itemCache: [UICollectionViewLayoutAttributes] = []

    override func prepare() {
        super.prepare()

        itemCache.removeAll()
        headerCache.removeAll()

        guard let collectionView = collectionView else {
            return
        }

        // Variable to track the width of the layout at the current state when the item is being drawn
        var layoutWidthIterator: CGFloat = 0.0

        for section in 0 ..< collectionView.numberOfSections {
            // Get the necessary data (if implemented) from the delegates else provide default values
            let insets: UIEdgeInsets = delegate?.collectionView(collectionView, insetsForItemsInSection: section) ?? UIEdgeInsets.zero
            let interItemSpacing: CGFloat = delegate?.collectionView(collectionView, itemSpacingInSection: section) ?? 0.0
            let headerSize = delegate?.collectionView(collectionView, heightForHeaderInSection: section) ?? 0.0

            // Variables to track individual item width and cumultative height of all items as they are being laid out.
            var itemSize: CGSize = .zero

            let attrHeader = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(row: 0, section: section))
            attrHeader.frame = CGRect(x: 0.0, y: layoutHeight, width: collectionView.frame.size.width, height: headerSize)
            layoutHeight += headerSize + insets.top
            headerCache.append(attrHeader)

            for item in 0 ..< collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)

                itemSize = delegate?.collectionView(collectionView, sizeForPillAtIndexPath: indexPath) ?? .zero

                if (layoutWidthIterator + itemSize.width + insets.left + insets.right) > collectionView.frame.width {
                    // If the current row width (after this item being laid out) is exceeding the width of the collection view content, put it in the next line
                    layoutWidthIterator = 0.0
                    layoutHeight += itemSize.height + interItemSpacing
                }

                let frame = CGRect(x: layoutWidthIterator + insets.left, y: layoutHeight, width: itemSize.width, height: itemSize.height)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                itemCache.append(attributes)
                layoutWidthIterator = layoutWidthIterator + frame.width + interItemSpacing
            }

            layoutHeight += itemSize.height + insets.bottom
            layoutWidthIterator = 0.0
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        super.layoutAttributesForElements(in: rect)

        var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []

        for attributes in itemCache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }

        for attributes in headerCache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }

        return visibleLayoutAttributes
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        return headerCache[indexPath.section]
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        super.layoutAttributesForItem(at: indexPath)
        return itemCache[indexPath.row]
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: layoutHeight)
    }

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        layoutHeight = 0.0
        return true
    }
}
