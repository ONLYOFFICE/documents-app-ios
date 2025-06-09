//
//  ASCFiltersViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 29.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCFiltersViewControllerDelegate: AnyObject {
    func updateData(filterText: String, id: String?)
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

    var viewModel: FiltersCollectionViewModel = .empty {
        didSet {
            if isViewLoaded {
                reloadColletionView()
            }
            if viewModel.state == .loading {
                showLoading()
            } else {
                hideLoading()
                showResultsButton.setTitle(viewModel.actionButtonViewModel.text, for: .normal)
                showResultsButton.isEnabled = viewModel.actionButtonViewModel.isActive
                showResultsButton.backgroundColor = viewModel.actionButtonViewModel.backgroundColor
                showResultsButton.titleColorForNormal = viewModel.actionButtonViewModel.textColor
                showResultsButton.titleColorForDisabled = viewModel.actionButtonViewModel.textColor
            }
        }
    }

    var collectionView: UICollectionView!
    private var activityIndicator: UIActivityIndicatorView!
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
}

private extension ASCFiltersViewController {
    // MARK: - Activity Indicator

    func showLoading() {
        showResultsButton.setTitle("", for: .normal)

        if activityIndicator == nil {
            activityIndicator = createActivityIndicator()
        }
        showSpinning()
    }

    func hideLoading() {
        activityIndicator?.stopAnimating()
    }

    func createActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }

    func showSpinning() {
        showResultsButton.addSubview(activityIndicator)
        activityIndicator.anchor(top: showResultsButton.topAnchor,
                                 leading: showResultsButton.leadingAnchor,
                                 bottom: showResultsButton.bottomAnchor,
                                 trailing: showResultsButton.trailingAnchor)
        activityIndicator.startAnimating()
    }

    // MARK: - Cell Actions

    func resetCell(at indexPath: IndexPath) {
        viewModel.didFilterResetBtnTapped(getFilterViewModel(indexPath: indexPath))
    }

    func selectedItem(in section: Int) -> IndexPath? {
        for (filterIndex, _) in viewModel.data[section].filters.enumerated() {
            if viewModel.data[section].filters[filterIndex].isSelected {
                return IndexPath(item: filterIndex, section: section)
            }
        }
        return nil
    }

    // MARK: - Configure

    func showResultButtonConstraints() {
        view.addSubview(showResultsButton)
        showResultsButton.anchor(
            leading: view.leadingAnchor,
            bottom: view.safeAreaLayoutGuide.bottomAnchor,
            trailing: view.trailingAnchor,
            padding: UIEdgeInsets(
                top: 0,
                left: Constants.leftRightInserts,
                bottom: 10,
                right: Constants.leftRightInserts
            ),
            size: CGSize(
                width: 0,
                height: Constants.buttonHeight
            )
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
            title: ASCLocalization.Common.cancel,
            style: UIBarButtonItem.Style.plain,
            target: self,
            action: #selector(cancelBarButtonItemTapped)
        )
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.leftBarButtonItem = leftBarButton
    }

    func setupCollectionView() {
        let layout = ASCCommon.isRTL
            ? ASCRightAlignedCollectionViewFlowLayout()
            : ASCLeftAlignedCollectionViewFlowLayout()

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
            leading: view.leadingAnchor,
            bottom: showResultsButton.topAnchor,
            trailing: view.trailingAnchor,
            padding: UIEdgeInsets(top: 0, left: Constants.leftRightInserts, bottom: 0, right: Constants.leftRightInserts)
        )
    }

    func getFilterViewModel(indexPath: IndexPath) -> FilterViewModel {
        viewModel.data[indexPath.section].filters[indexPath.item]
    }

    func reloadColletionView() {
        collectionView.removeFromSuperview()
        setupCollectionView()
    }

    // MARK: - objc methods

    @objc func resetBarButtonItemTapped() {
        viewModel.resetButtonClosure()
    }

    @objc func cancelBarButtonItemTapped() {
        dismiss(animated: true)
    }

    @objc func onShowResultsButtonTapped() {
        viewModel.actionButtonClosure()
        dismiss(animated: true)
    }
}

extension ASCFiltersViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelectedClosure(getFilterViewModel(indexPath: indexPath))
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.data.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.data[section].filters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ASCFiltersCollectionViewCell.identifier, for: indexPath) as? ASCFiltersCollectionViewCell
        let filterViewModel = getFilterViewModel(indexPath: indexPath)
        if filterViewModel.isSelected {
            if filterViewModel.isFilterResetBtnShowen == true {
                cell?.addDeselectFilterBtnToView()
            }
            cell?.labelText.textColor = .white
            cell?.backgroundColor = Asset.Colors.brend.color
        } else {
            cell?.labelText.textColor = filterViewModel.defaultTextColor
            cell?.backgroundColor = Asset.Colors.filterCapsule.color
        }
        cell?.deselectFilterBtn.add(for: .touchUpInside) {
            self.viewModel.didFilterResetBtnTapped(filterViewModel)
        }
        cell?.deselectFilterBtn.isHidden = !filterViewModel.isFilterResetBtnShowen
        cell?.setLabel(filterViewModel.filterName)

        return cell!
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ASCFiltersCollectionViewHeader.identifier, for: indexPath) as? ASCFiltersCollectionViewHeader
        header?.setupLabel("\(viewModel.data[indexPath.section].sectionName)")
        header?.backgroundColor = .clear
        return header!
    }
}

extension ASCFiltersViewController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let filterViewModel = getFilterViewModel(indexPath: indexPath)
        let label = filterViewModel.filterName
        let referenceSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: ASCFiltersCollectionViewCell.pillHeight)
        let calculatedSize = (label as NSString).boundingRect(with: referenceSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)], context: nil)
        if filterViewModel.isFilterResetBtnShowen == true {
            return CGSize(width: min(calculatedSize.width, collectionView.frame.width * 0.8) + Constants.cellLeftRightPadding + Constants.cellLeftRightPadding, height: ASCFiltersCollectionViewCell.pillHeight)
        } else {
            return CGSize(width: min(calculatedSize.width, collectionView.frame.width * 0.8) + Constants.cellLeftRightPadding, height: ASCFiltersCollectionViewCell.pillHeight)
        }
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
