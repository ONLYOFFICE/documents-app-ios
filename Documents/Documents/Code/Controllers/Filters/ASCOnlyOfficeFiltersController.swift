//
//  ASCOnlyOfficeFiltersController.swift
//  Documents
//
//  Created by Лолита Чернышева on 05.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCOnlyOfficeFiltersController {
    // MARK: -  properties

    private var currentSelectedAuthorFilterType: ApiFilterType?
    private let builder: ASCFiltersCollectionViewModelBuilder
    private var currentLoading = false
    private var itemsCount = 0
    private let filtersViewController: ASCFiltersViewController
    private lazy var selectUserViewController: ASCSelectUserViewController = {
        let controller = ASCSelectUserViewController()
        controller.delegate = self
        return controller
    }()

    private lazy var selectGroupViewController: ASCSelectGroupViewController = {
        let controller = ASCSelectGroupViewController()
        controller.delegate = self
        return controller
    }()

    // MARK: - public properties

    var folder: ASCFolder?
    var provider: ASCOnlyofficeProvider?
    var filtersParams: [String: Any]? {
        let hasSelectedFilter = filterModels.map { $0.isSelected }.contains(true) || authorsModels.compactMap { $0.selectedName }.count > 0
        guard hasSelectedFilter else { return nil }
        var params: [String: Any] = [:]
        if let model = filterModels.first(where: { $0.isSelected }) {
            params["filterType"] = model.filterType.rawValue
        }
        if let model = authorsModels.first(where: { $0.selectedName != nil }),
           let id = model.id
        {
            params["userIdOrGroupId"] = id
        }
        return params
    }

    var actionButtonTappedClousure: () -> Void = {}

    // MARK: - data properties

    private var filterModels: [ASCDocumentsFilterModel] = [
        ASCDocumentsFilterModel(filterName: FiltersName.folders.localizedString(), isSelected: false, filterType: .folders),
        ASCDocumentsFilterModel(filterName: FiltersName.documents.localizedString(), isSelected: false, filterType: .documents),
        ASCDocumentsFilterModel(filterName: FiltersName.presentations.localizedString(), isSelected: false, filterType: .presentations),
        ASCDocumentsFilterModel(filterName: FiltersName.spreadsheets.localizedString(), isSelected: false, filterType: .spreadsheets),
        ASCDocumentsFilterModel(filterName: FiltersName.images.localizedString(), isSelected: false, filterType: .images),
        ASCDocumentsFilterModel(filterName: FiltersName.media.localizedString(), isSelected: false, filterType: .media),
        ASCDocumentsFilterModel(filterName: FiltersName.archives.localizedString(), isSelected: false, filterType: .archive),
        ASCDocumentsFilterModel(filterName: FiltersName.allFiles.localizedString(), isSelected: false, filterType: .files),
    ]

    private var authorsModels: [ActionFilterModel] = [
        ActionFilterModel(defaultName: FiltersName.users.localizedString(), selectedName: nil, filterType: .user),
        ActionFilterModel(defaultName: FiltersName.groups.localizedString(), selectedName: nil, filterType: .group),
    ]

    // MARK: - init

    init(builder: ASCFiltersCollectionViewModelBuilder, filtersViewController: ASCFiltersViewController, itemsCount: Int) {
        self.builder = builder
        self.filtersViewController = filtersViewController
        self.itemsCount = itemsCount
        buildActions()
    }

    func updateViewModel() {
        let viewModel = builder.buildViewModel(
            state: currentLoading ? .loading : .normal,
            filtersContainers: [
                .init(sectionName: FiltersSection.type.localizedString(), elements: filterModels),
                .init(sectionName: FiltersSection.author.localizedString(), elements: authorsModels),
            ], actionButtonTitle: itemsCount > 0
                ? String.localizedStringWithFormat(NSLocalizedString("Show %d results", comment: ""), itemsCount)
                : NSLocalizedString("Show results", comment: "")
        )
        filtersViewController.viewModel = viewModel
    }

    private func buildActions() {
        buildDidSelectedClosure()
        buildResetButtonClosureBuilder()
        builder.actionButtonClosure = { [weak self] in self?.actionButtonTappedClousure() }
    }

    private func buildDidSelectedClosure() {
        builder.didSelectedClosure = { [weak self] filterViewModel in
            guard let self = self else { return }

            let isFilterModelsContainsSelectedId: Bool = self.filterModels.map { $0.filterType.rawValue }.contains(filterViewModel.id)
            let isAthorModelsContainsSelectedId: Bool = self.authorsModels.map { $0.filterType.rawValue }.contains(filterViewModel.id)

            if isFilterModelsContainsSelectedId {
                let previousSelectedFilter = self.filterModels.first(where: { $0.isSelected })
                for (index, filterModel) in self.filterModels.enumerated() {
                    self.filterModels[index].isSelected = filterModel.filterType.rawValue == filterViewModel.id && previousSelectedFilter?.filterType.rawValue != filterViewModel.id
                }
                self.runPreload()
            }

            if isAthorModelsContainsSelectedId {
                switch ApiFilterType(rawValue: filterViewModel.id) {
                case .user:
                    let navigationVC = UINavigationController(rootASCViewController: self.selectUserViewController)
                    ASCViewControllerManager.shared.topViewController?.navigationController?.present(navigationVC, animated: true)
                    self.currentSelectedAuthorFilterType = .user
                case .group:
                    let navigationVC = UINavigationController(rootASCViewController: self.selectGroupViewController)
                    ASCViewControllerManager.shared.topViewController?.navigationController?.present(navigationVC, animated: true)
                    self.currentSelectedAuthorFilterType = .group
                default: return
                }
                self.updateViewModel()
            }
        }
    }

    private func buildResetButtonClosureBuilder() {
        builder.resetButtonClosure = { [weak self] in
            guard let self = self else { return }

            for (index, _) in self.filterModels.enumerated() {
                self.filterModels[index].isSelected = false
            }

            for (index, _) in self.authorsModels.enumerated() {
                self.authorsModels[index].selectedName = nil
            }
            self.runPreload()
        }
    }

    private func runPreload() {
        guard let provider = provider, let folder = folder else { return }

        currentLoading = true
        updateViewModel()

        let completion: (Int) -> Void = { [weak self] count in
            self?.itemsCount = count
            self?.currentLoading = false
            self?.updateViewModel()
        }

        provider.fetch(for: folder, parameters: ["filters": filtersParams], completeon: { [weak self] provider, result, success, error in
            guard success else {
                completion(self?.itemsCount ?? 0)
                return
            }
            completion(provider.total)
        })
    }
}

extension ASCOnlyOfficeFiltersController: ASCFiltersViewControllerDelegate {
    func updateData(filterText itemText: String, id: String?) {
        authorsModels.enumerated().forEach { index, _ in
            authorsModels[index].selectedName = nil
        }
        switch currentSelectedAuthorFilterType {
        case .user, .group:
            if let index = authorsModels.firstIndex(where: { $0.filterType == currentSelectedAuthorFilterType }) {
                authorsModels[index].selectedName = itemText
                authorsModels[index].id = id
            }
        default: break
        }

        currentSelectedAuthorFilterType = nil
        runPreload()
    }
}
