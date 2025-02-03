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
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.backgroundColor = .systemBackground
        configuration.showsSeparators = false
        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] itemIndex in
            self?.ascDocumentsDelegate?.swipeActionsConfiguration(collectionView: self, indexPath: itemIndex) ?? UISwipeActionsConfiguration()
        }
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    private func makeGridLayout() -> UICollectionViewCompositionalLayout {
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

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}
