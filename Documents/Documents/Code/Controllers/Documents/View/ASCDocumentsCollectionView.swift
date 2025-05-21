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

    public func updateLayout() {
        setCollectionViewLayout(makeCollectionLayout(), animated: true)
    }

    private func makeCollectionLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in

            if sectionIndex == 0 {
                return self?.layoutType == .grid ? self?.makeGridLayout() : self?.makeTableLayout(layoutEnvironment: layoutEnvironment)
            } else {
                return self?.makeLoaderLayout()
            }
        }
    }

    // MARK: - Private

    private func makeTableLayout(layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.backgroundColor = .systemBackground
        configuration.showsSeparators = false
        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] itemIndex in
            self?.ascDocumentsDelegate?.swipeActionsConfiguration(collectionView: self, indexPath: itemIndex) ?? UISwipeActionsConfiguration()
        }

        return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
    }

    private func makeGridLayout() -> NSCollectionLayoutSection {
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

        let count = Int((superview?.width ?? 330) / 110.0)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
        group.interItemSpacing = .fixed(groupSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: sectionSpacing, leading: sectionSpacing, bottom: sectionSpacing, trailing: sectionSpacing)
        section.interGroupSpacing = groupSpacing

        return section
    }

    private func makeLoaderLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(60)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 10, leading: 0, bottom: 20, trailing: 0)

        return section
    }
}
