//
//  ASCDocumentsCollectionView.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.02.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import UIKit

@MainActor
protocol ASCDocumentsCollectionViewDelegate: NSObjectProtocol {
    func swipeActionsConfiguration(collectionView: UICollectionView?, indexPath: IndexPath) -> UISwipeActionsConfiguration?
}

@MainActor
class ASCDocumentsCollectionView: UICollectionView {
    // MARK: - Properties

    weak var ascDocumentsDelegate: ASCDocumentsCollectionViewDelegate?

    var layoutType: ASCEntityViewLayoutType? {
        didSet {
            if oldValue == layoutType { return }
            updateLayout()
        }
    }

    // MARK: - Lifecycle Methods

    func updateLayout() {
        switch layoutType {
        case .grid:
            setCollectionViewLayout(makeGridLayout(), animated: true)

        case .list:
            setCollectionViewLayout(makeTableLayout(), animated: true)

        default:
            setCollectionViewLayout(UICollectionViewLayout(), animated: true)
        }
    }

    // MARK: - Private

    private func makeTableLayout() -> UICollectionViewCompositionalLayout {
        contentInset.bottom = 0

        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.backgroundColor = .systemBackground
        configuration.showsSeparators = false
        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] itemIndex in
            self?.ascDocumentsDelegate?.swipeActionsConfiguration(collectionView: self, indexPath: itemIndex) ?? UISwipeActionsConfiguration()
        }
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    private func makeGridLayout() -> UICollectionViewCompositionalLayout {
        return GridCompositionalLayout(collectionView: self)
    }
}

// MARK: - GridCompositionalLayout

class GridCompositionalLayout: UICollectionViewCompositionalLayout {
    init(collectionView: UICollectionView) {
        collectionView.contentInset.bottom = 80

        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { sectionIndex, environment in
            let groupSpacing: CGFloat = 4
            let sectionSpacing: CGFloat = 16

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(190)
            )

            let count = Int((collectionView.superview?.width ?? 330) / 110.0)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
            group.interItemSpacing = .fixed(groupSpacing)

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: sectionSpacing, leading: sectionSpacing, bottom: sectionSpacing, trailing: sectionSpacing)
            section.interGroupSpacing = groupSpacing

            return section
        }

        super.init(sectionProvider: sectionProvider)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let originalAttributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() }) as? [UICollectionViewLayoutAttributes] else {
            return nil
        }

        let attributes = NSArray(array: originalAttributes, copyItems: true) as! [UICollectionViewLayoutAttributes]

        let loaderIndices = attributes.enumerated()
            .filter { isLoaderCell(at: $0.element.indexPath) }
            .map { $0.offset }

        guard !loaderIndices.isEmpty else {
            return attributes
        }

        for index in loaderIndices {
            let attribute = attributes[index]

            let sameRowAttributes = attributes.filter {
                $0 != attribute &&
                    abs($0.frame.origin.y - attribute.frame.origin.y) < 10
            }

            let updateLoaderCellAttributes: (CGFloat, UICollectionViewLayoutAttributes) -> Void = { [weak self] newY, attribute in
                let x: CGFloat = 0
                let y = newY
                let width = self?.collectionView?.bounds.width ?? 0
                let height: CGFloat = 20

                attribute.frame = CGRect(x: x, y: y, width: width, height: height)
                attribute.zIndex = 1000
            }

            if !sameRowAttributes.isEmpty {
                let maxY = attributes.map { $0.frame.maxY }.max() ?? attribute.frame.origin.y

                updateLoaderCellAttributes(maxY, attribute)
            } else {
                updateLoaderCellAttributes(attribute.frame.origin.y, attribute)
            }
        }

        return attributes
    }

    private func isLoaderCell(at indexPath: IndexPath) -> Bool {
        guard
            let collectionView,
            let documentsViewController = collectionView.dataSource as? ASCDocumentsViewController
        else { return false }

        guard indexPath.row < (collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: indexPath.section) ?? 0) else {
            return false
        }

        if let cell = collectionView.cellForItem(at: indexPath) {
            return cell is ASCLoaderViewCell
        }

        if indexPath.row == collectionView.numberOfItems(inSection: indexPath.section) - 1, indexPath.row < documentsViewController.total - 1 {
            return true
        }

        return false
    }
}
