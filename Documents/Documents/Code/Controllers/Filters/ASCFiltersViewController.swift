//
//  ASCFiltersViewController.swift
//  Documents
//
//  Created by Лолита Чернышева on 29.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCFiltersViewController: UIViewController {
    var sections: [String] = ["Type", "Author", "Search"]
    var filters: [[String]] = [["Folders", "Documents", "Presentations", "Spreadsheets", "Images", "Media", "Archives", "All files"],
                               ["Users", "Groups"],
                               ["Exclude subfolders"]]

    // Set by constraints at the cell level. Currently hardcoding here. But can be derived from the actual constraints in the cell
    let cellLeftRightPadding: CGFloat = 32.0

    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.Colors.tableCategoryBackground.color
        setupCollectionView()
    }
}

private extension ASCFiltersViewController {
    func setupCollectionView() {
        let pillLayout = ASCPillLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: pillLayout)
        collectionView.backgroundColor = .clear
        guard let collectionView = collectionView else { return }
        collectionView.register(ASCFiltersCollectionViewCell.self,
                                forCellWithReuseIdentifier: ASCFiltersCollectionViewCell.identifier)
        collectionView.register(ASCFiltersCollectionViewHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: ASCFiltersCollectionViewHeader.identifier)

        collectionView.dataSource = self
        collectionView.delegate = self
        pillLayout.delegate = self
        collectionView.collectionViewLayout = pillLayout
        view.addSubview(collectionView)
        collectionView.frame = view.bounds
    }
}

extension ASCFiltersViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return filters.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ASCFiltersCollectionViewCell.identifier, for: indexPath) as? ASCFiltersCollectionViewCell
        cell?.setLabel(filters[indexPath.section][indexPath.row])
        return cell!
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ASCFiltersCollectionViewHeader.identifier, for: indexPath) as? ASCFiltersCollectionViewHeader
        header?.setupLabel("\(sections[indexPath.section])")
        header?.backgroundColor = Asset.Colors.tableCategoryBackground.color
        return header!
    }
}

extension ASCFiltersViewController: ASCPillLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, sizeForPillAtIndexPath indexPath: IndexPath) -> CGSize {
        let label = filters[indexPath.section][indexPath.row]
        let referenceSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: ASCFiltersCollectionViewCell.pillHeight)
        let calculatedSize = (label as NSString).boundingRect(with: referenceSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)], context: nil)
        return CGSize(width: calculatedSize.width + cellLeftRightPadding, height: ASCFiltersCollectionViewCell.pillHeight)
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52.0
    }

    func collectionView(_ collectionView: UICollectionView, insetsForItemsInSection section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
    }

    func collectionView(_ collectionView: UICollectionView, itemSpacingInSection section: Int) -> CGFloat {
        return 12.0
    }
}
