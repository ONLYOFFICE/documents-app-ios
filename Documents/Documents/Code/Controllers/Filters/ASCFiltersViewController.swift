//
//  ASCFiltersViewController.swift
//  Documents
//
//  Created by Лолита Чернышева on 29.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCFiltersViewControllerDelegate: AnyObject {
    func updateData(filterText: String)
}

class ASCFiltersViewController: UIViewController {
    private enum Constants {
        static let cellLeftRightPadding: CGFloat = 32.0
        static let leftRightInserts: CGFloat = 16.0
        static let buttonHeight: CGFloat = 52.0
        static let headerHeight: CGFloat = 22.0
        static let itemSpace: CGFloat = 16.0
    }

    // MARK: - Properties
    
    var data: [ASCDocumentsSectionModel] = [
        ASCDocumentsSectionModel(sectionName: NSLocalizedString("Type", comment: ""),
                                 filters: [
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("Folders", comment: ""), isSelected: false, filter: .folders),
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("Documents", comment: ""), isSelected: false, filter: .documents),
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("Presentations", comment: ""), isSelected: false, filter: .presentations),
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("Spreadsheets", comment: ""), isSelected: false, filter: .spreadsheets),
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("Images", comment: ""), isSelected: false, filter: .images),
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("Media", comment: ""), isSelected: false, filter: .media),
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("Archives", comment: ""), isSelected: false, filter: .archive),
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("All files", comment: ""), isSelected: false, filter: .files),
                                 ]),
        ASCDocumentsSectionModel(sectionName: NSLocalizedString("Author", comment: ""),
                                 filters: [
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("Users", comment: ""), isSelected: false, filter: .user),
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("Groups", comment: ""), isSelected: false, filter: .group),
                                 ]),
        ASCDocumentsSectionModel(sectionName: NSLocalizedString("Search", comment: ""),
                                 filters: [
                                    ASCDocumentsFilterModel(filterName: NSLocalizedString("Exclude subfolders", comment: ""), isSelected: false, filter: .byExtension),
                                 ]),
    ]

    let resultCount = 100
    var folderId: String?
    var showResultsCompletion: () -> Void = {}
    var collectionView: UICollectionView!
    lazy var selectUserViewController: ASCSelectUserViewController = {
        let controller = ASCSelectUserViewController()
        controller.delegate = self
        return controller
    }()

    lazy var selectGroupViewController: ASCSelectGroupViewController = {
        let controller = ASCSelectGroupViewController()
        controller.delegate = self
        return controller
    }()

    private lazy var showResultsButton: ASCButtonStyle = {
        $0.styleType = .blank
        return $0
    }(ASCButtonStyle())
    
    // MARK: - Lifecycle Methods

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.Colors.tableCategoryBackground.color
        setupNavigationBar()
        showResultButtonConstraints()
        setupCollectionView()
        showResultsButton.addTarget(self, action: #selector(onShowResultsButtonTapped), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .never
    }

    func fiterTypeIdentifier() -> FilterType {
        for (sectionIndex, section) in data.enumerated() {
            for (filterIndex, _) in section.filters.enumerated() {
                if data[sectionIndex].filters[filterIndex].isSelected == true {
                    return data[sectionIndex].filters[filterIndex].filter
                }
            }
        }
        return .none
    }
}

private extension ASCFiltersViewController {
    func deselectFiltersInSection(byIndex sectionIndex: Int) {
        for (filterIndex, _) in data[sectionIndex].filters.enumerated() {
            data[sectionIndex].filters[filterIndex].isSelected = false
        }
    }
    
    func resetCell(at indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ASCFiltersCollectionViewCell {
            if indexPath.section == 1 {
                cell.labelText.textColor = Asset.Colors.brend.color
            } else {
                cell.labelText.textColor = .black
            }
            cell.backgroundColor = Asset.Colors.viewBackground.color
        }
    }
    
    func selectedItem(in section: Int) -> IndexPath? {
        for (filterIndex, _) in data[section].filters.enumerated() {
            if data[section].filters[filterIndex].isSelected {
                return IndexPath(item: filterIndex, section: section)
            }
        }
        return nil
    }
    
    func selectFilter(at indexPath: IndexPath) {
        data[indexPath.section].filters[indexPath.item].isSelected = true
    }

    func showResultButtonConstraints() {
        showResultsButton.setTitle(String.localizedStringWithFormat(
            NSLocalizedString("Show %d results", comment: ""), resultCount
        ), for: .normal)
        
        view.addSubview(showResultsButton)
        showResultsButton.anchor(
            left: view.leftAnchor,
            bottom: view.safeAreaLayoutGuide.bottomAnchor,
            right: view.rightAnchor,
            leftConstant: Constants.leftRightInserts,
            bottomConstant: 10,
            rightConstant: Constants.leftRightInserts,
            heightConstant: Constants.buttonHeight
        )
    }
    
    func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = NSLocalizedString("Filters", comment: "")
        
        let rightBarButton = UIBarButtonItem(
            title: NSLocalizedString("Reset", comment: ""),
            style: UIBarButtonItem.Style.plain,
            target: self,
            action: #selector(resetBarButtonItemTapped)
        )
        let leftBarButton = UIBarButtonItem(
            title: NSLocalizedString("Cancel", comment: ""),
            style: UIBarButtonItem.Style.plain,
            target: self,
            action: #selector(cancelBarButtonItemTapped)
        )
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func setupCollectionView() {
        let layout = LeftAlignedCollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        guard let collectionView = collectionView else { return }
        collectionView.register(ASCFiltersCollectionViewCell.self,
                                forCellWithReuseIdentifier: ASCFiltersCollectionViewCell.identifier)
        collectionView.register(ASCFiltersCollectionViewHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: ASCFiltersCollectionViewHeader.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = layout
        view.addSubview(collectionView)
        setupCollectionViewConstraints()
    }
    
    func setupCollectionViewConstraints() {
        collectionView.anchor(
            top: view.safeAreaLayoutGuide.topAnchor,
            left: view.leftAnchor,
            bottom: showResultsButton.topAnchor,
            right: view.rightAnchor,
            leftConstant: Constants.leftRightInserts,
            rightConstant: Constants.leftRightInserts
        )
    }

    @objc func resetBarButtonItemTapped() {
        for (sectionIndex, section) in data.enumerated() {
            for (filterIndex, _) in section.filters.enumerated() {
                data[sectionIndex].filters[filterIndex].isSelected = false
            }
        }
        reloadColletionView()
    }

    @objc func cancelBarButtonItemTapped() {
        dismiss(animated: true)
    }

    @objc func onShowResultsButtonTapped() {
        showResultsCompletion()
        dismiss(animated: true)
    }

    private func reloadColletionView() {
        collectionView.removeFromSuperview()
        setupCollectionView()
    }
}

extension ASCFiltersViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    //
    // TODO: Implement the logic for changing the appearance of the cell inside the class.
    // Use property like Selected.
    // Add dark mode support
    //
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedItemIndexPath = selectedItem(in: indexPath.section) {
            resetCell(at: selectedItemIndexPath)
            deselectFiltersInSection(byIndex: indexPath.section)
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) as? ASCFiltersCollectionViewCell {
            cell.labelText.textColor = Asset.Colors.viewBackground.color
            cell.backgroundColor = Asset.Colors.brend.color
            selectFilter(at: indexPath)
        }

        if indexPath.section == 1, indexPath.item == 0 {
            let navigationVC = UINavigationController(rootASCViewController: selectUserViewController)
            navigationController?.present(navigationVC, animated: true)
        }

        if indexPath.section == 1, indexPath.item == 1 {
            let navigationVC = UINavigationController(rootASCViewController: selectGroupViewController)
            navigationController?.present(navigationVC, animated: true)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ASCFiltersCollectionViewCell.identifier, for: indexPath) as? ASCFiltersCollectionViewCell
        cell?.setLabel(data[indexPath.section].filters[indexPath.row].filterName)
        if indexPath.section == 1 {
            cell?.labelText.textColor = Asset.Colors.brend.color
        }
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ASCFiltersCollectionViewHeader.identifier, for: indexPath) as? ASCFiltersCollectionViewHeader
        header?.setupLabel("\(data[indexPath.section].sectionName)")
        return header!
    }
}

extension ASCFiltersViewController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let label = data[indexPath.section].filters[indexPath.row].filterName
        let referenceSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: ASCFiltersCollectionViewCell.pillHeight)
        let calculatedSize = (label as NSString).boundingRect(with: referenceSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)], context: nil)
        return CGSize(width: calculatedSize.width + Constants.cellLeftRightPadding, height: ASCFiltersCollectionViewCell.pillHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Constants.itemSpace
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Constants.itemSpace
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: Constants.itemSpace, left: 0, bottom: Constants.itemSpace, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.size.width, height: Constants.headerHeight)
    }
}

extension ASCFiltersViewController {
    typealias ErrorMessage = String
    
    enum RequestResult {
        case success
        case failure(ErrorMessage)
    }
}

extension ASCFiltersViewController: ASCFiltersViewControllerDelegate {
    func updateData(filterText itemText: String) {
        guard let indexPath = selectedItem(in: 1) else { return }
        data[indexPath.section].filters[indexPath.item].filterName = itemText
        reloadColletionView()
    }
}
