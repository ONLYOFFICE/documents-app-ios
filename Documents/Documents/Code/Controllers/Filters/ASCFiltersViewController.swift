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
    var filters: [[ASCDocumentsFilterModel]] = [[ASCDocumentsFilterModel(filterName: "Folders", isSelected: false),
                                                 ASCDocumentsFilterModel(filterName: "Documents", isSelected: false),
                                                 ASCDocumentsFilterModel(filterName: "Presentations", isSelected: false),
                                                 ASCDocumentsFilterModel(filterName: "Spreadsheets", isSelected: false),
                                                 ASCDocumentsFilterModel(filterName: "Images", isSelected: false),
                                                 ASCDocumentsFilterModel(filterName: "Media", isSelected: false),
                                                 ASCDocumentsFilterModel(filterName: "Archives", isSelected: false),
                                                 ASCDocumentsFilterModel(filterName: "All files", isSelected: false)],
                                                [ASCDocumentsFilterModel(filterName: "Users", isSelected: false),
                                                 ASCDocumentsFilterModel(filterName: "Groups", isSelected: false)],
                                                [ASCDocumentsFilterModel(filterName: "Exclude subfolders", isSelected: false)]]

    // Set by constraints at the cell level. Currently hardcoding here. But can be derived from the actual constraints in the cell
    let cellLeftRightPadding: CGFloat = 32.0

    var collectionView: UICollectionView!
    var showResultsButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.Colors.tableCategoryBackground.color
        setupNavigationBar()
        showResultButtonConstraints()
        setupCollectionView()
    }

    private func showResultButtonConstraints() {
        showResultsButton = UIButton()
        showResultsButton.backgroundColor = Asset.Colors.viewBackground.color
        showResultsButton.setTitleColorForAllStates(Asset.Colors.brend.color)
        showResultsButton.layer.cornerRadius = 10
        showResultsButton.setTitle(NSLocalizedString("Show 100 results", comment: ""), for: .normal)

        view.addSubview(showResultsButton)
        showResultsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            showResultsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            showResultsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            showResultsButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -44),
            showResultsButton.heightAnchor.constraint(equalToConstant: 52),

        ])
    }
}

private extension ASCFiltersViewController {
    func setupNavigationBar() {
        let navigationTitle = UILabel()
        navigationTitle.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        navigationTitle.text = NSLocalizedString("Filters", comment: "")
        navigationItem.titleView = navigationTitle

        let rightBarButton = UIBarButtonItem(title: NSLocalizedString("Reset", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(resetBarButtonItemTapped))
        let leftBarButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancelBarButtonItemTapped))
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.leftBarButtonItem = leftBarButton
    }

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
        collectionView.backgroundColor = Asset.Colors.tableBackground.color
        collectionView.dataSource = self
        collectionView.delegate = self
        pillLayout.delegate = self
        collectionView.collectionViewLayout = pillLayout
        view.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 70),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.bottomAnchor.constraint(equalTo: showResultsButton.topAnchor),
        ])
    }

    @objc func resetBarButtonItemTapped() {}

    @objc func cancelBarButtonItemTapped() {
        dismiss(animated: true)
    }
}

extension ASCFiltersViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ASCFiltersCollectionViewCell {
            if (filters[indexPath.section][indexPath.row].isSelected) == false {
                filters[indexPath.section][indexPath.row].isSelected = true
                cell.labelText.textColor = Asset.Colors.viewBackground.color
                cell.backgroundColor = Asset.Colors.brend.color
            } else {
                if indexPath.section == 1 {
                    cell.labelText.textColor = Asset.Colors.brend.color
                } else {
                    cell.labelText.textColor = .black
                }
                cell.backgroundColor = Asset.Colors.viewBackground.color
                filters[indexPath.section][indexPath.row].isSelected = false
            }
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return filters.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ASCFiltersCollectionViewCell.identifier, for: indexPath) as? ASCFiltersCollectionViewCell
        cell?.setLabel(filters[indexPath.section][indexPath.row].filterName)
        if indexPath.section == 1 {
            cell?.labelText.textColor = Asset.Colors.brend.color
        }
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
        let label = filters[indexPath.section][indexPath.row].filterName
        let referenceSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: ASCFiltersCollectionViewCell.pillHeight)
        let calculatedSize = (label as NSString).boundingRect(with: referenceSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)], context: nil)
        return CGSize(width: calculatedSize.width + cellLeftRightPadding, height: ASCFiltersCollectionViewCell.pillHeight)
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderInSection section: Int) -> CGFloat {
        return 22.0
    }

    func collectionView(_ collectionView: UICollectionView, insetsForItemsInSection section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16.0, left: 0, bottom: 16.0, right: 16.0)
    }

    func collectionView(_ collectionView: UICollectionView, itemSpacingInSection section: Int) -> CGFloat {
        return 16.0
    }
}
