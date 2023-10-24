//
//  ASCLocalFilterController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 30.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCLocalFilterController: ASCFiltersControllerProtocol {
    struct State {
        enum DataType: CaseIterable {
            case extensionFilters
            case searchFilters
        }

        var filterModels: [ASCDocumentsFilterModel]
        var searchFilterModels: [ASCDocumentsFilterModel]
        var itemsCount: Int

        static var defaultState: (Int) -> State = { count in
            State(filterModels: [
                ASCDocumentsFilterModel(filterName: FiltersName.folders.localizedString(), isSelected: false, filterType: .folders),
                ASCDocumentsFilterModel(filterName: FiltersName.documents.localizedString(), isSelected: false, filterType: .documents),
                ASCDocumentsFilterModel(filterName: FiltersName.presentations.localizedString(), isSelected: false, filterType: .presentations),
                ASCDocumentsFilterModel(filterName: FiltersName.spreadsheets.localizedString(), isSelected: false, filterType: .spreadsheets),
                ASCDocumentsFilterModel(filterName: FiltersName.images.localizedString(), isSelected: false, filterType: .images),
                ASCDocumentsFilterModel(filterName: FiltersName.media.localizedString(), isSelected: false, filterType: .media),
                ASCDocumentsFilterModel(filterName: FiltersName.archives.localizedString(), isSelected: false, filterType: .archive),
                ASCDocumentsFilterModel(filterName: FiltersName.allFiles.localizedString(), isSelected: false, filterType: .files),
            ],
            searchFilterModels: [ASCDocumentsFilterModel(filterName: FiltersName.excludeSubfolders.localizedString(), isSelected: false, filterType: .excludeSubfolders)],
            itemsCount: count)
        }
    }

    // MARK: -  state

    private var tempState: State
    private var appliedState: State?

    // MARK: -  properties

    private var currentSelectedAuthorFilterType: ApiFilterType?
    private let builder: ASCFiltersCollectionViewModelBuilder
    private var currentLoading = false

    // MARK: - public properties

    var folder: ASCFolder?
    var provider: ASCFileProviderProtocol?
    var filtersViewController: ASCFiltersViewController
    var filtersParams: [String: Any]? {
        guard let appliedState = appliedState else { return nil }
        return makeFilterParams(state: appliedState)
    }

    var isReset: Bool {
        !tempState.filterModels.map { $0.isSelected }.contains(true)
    }

    var onAction: () -> Void = {}

    // MARK: - init

    required init(
        builder: ASCFiltersCollectionViewModelBuilder,
        filtersViewController: ASCFiltersViewController,
        itemsCount: Int
    ) {
        self.builder = builder
        self.filtersViewController = filtersViewController
        tempState = .defaultState(itemsCount)
        buildActions()
    }

    func prepareForDisplay(total: Int) {
        if let appliedState = appliedState {
            tempState = appliedState
        } else {
            tempState = .defaultState(total)
        }
        runPreload()
    }

    private func hasSelectedFilter(state: State) -> Bool {
        var result = false
        State.DataType.allCases.forEach { type in
            switch type {
            case .extensionFilters:
                result = result || state.filterModels.map { $0.isSelected }.contains(true)
            case .searchFilters:
                result = result || state.searchFilterModels.map { $0.isSelected }.contains(true)
            }
        }
        return result
    }

    private func makeFilterParams(state: State) -> [String: Any] {
        var params: [String: Any] = ["withSubfolders": true]
        guard hasSelectedFilter(state: state) else { return params }

        State.DataType.allCases.forEach { type in
            switch type {
            case .extensionFilters:
                if let model = state.filterModels.first(where: { $0.isSelected }) {
                    params["filterType"] = model.filterType.rawValue
                }
            case .searchFilters:
                if let model = state.searchFilterModels.first(where: { $0.isSelected }) {
                    switch model.filterType {
                    case .excludeSubfolders:
                        params["withSubfolders"] = false
                    default:
                        log.error("UnsuppurtedFIlterType: \(model.filterType.rawValue)")
                    }
                }
            }
        }
        return params
    }

    private func updateViewModel() {
        let viewModel = builder.buildViewModel(
            state: currentLoading ? .loading : .normal,
            filtersContainers: [
                .init(sectionName: FiltersSection.type.localizedString(), elements: tempState.filterModels),
                .init(sectionName: FiltersSection.search.localizedString(), elements: tempState.searchFilterModels),
            ], actionButtonViewModel: tempState.itemsCount > 0
                ? ActionButtonViewModel(text: String.localizedStringWithFormat(NSLocalizedString("Show %d results", comment: ""), tempState.itemsCount),
                                        backgroundColor: Asset.Colors.filterCapsule.color,
                                        textColor: Asset.Colors.brend.color,
                                        isActive: true)
                : ActionButtonViewModel(text: NSLocalizedString("Nothing to show", comment: ""),
                                        backgroundColor: Asset.Colors.filterCapsule.color,
                                        textColor: Asset.Colors.tableCellSeparator.color,
                                        isActive: false)
        )
        filtersViewController.viewModel = viewModel
    }

    private func buildActions() {
        buildDidSelectedClosure()
        buildCommonResetButtonClosureBuilder()
        builder.actionButtonClosure = { [weak self] in
            self?.appliedState = self?.tempState
            self?.onAction()
        }
    }

    private func buildDidSelectedClosure() {
        builder.didSelectedClosure = { [weak self] filterViewModel in
            guard let self = self else { return }

            State.DataType.allCases.forEach { type in
                switch type {
                case .extensionFilters:
                    let isFilterModelsContainsSelectedId: Bool = self.tempState.filterModels.map { $0.filterType.rawValue }.contains(filterViewModel.id)

                    if isFilterModelsContainsSelectedId {
                        let previousSelectedFilter = self.tempState.filterModels.first(where: { $0.isSelected })
                        for (index, filterModel) in self.tempState.filterModels.enumerated() {
                            self.tempState.filterModels[index].isSelected = filterModel.filterType.rawValue == filterViewModel.id && previousSelectedFilter?.filterType.rawValue != filterViewModel.id
                        }
                        self.runPreload()
                    }
                case .searchFilters:
                    let isSearchModelsContainsSelectedId: Bool = self.tempState.searchFilterModels.map { $0.filterType.rawValue }.contains(filterViewModel.id)

                    if isSearchModelsContainsSelectedId {
                        let previousSelectedFilter = self.tempState.searchFilterModels.first(where: { $0.isSelected })
                        for (index, filterModel) in self.tempState.searchFilterModels.enumerated() {
                            self.tempState.searchFilterModels[index].isSelected = filterModel.filterType.rawValue == filterViewModel.id && previousSelectedFilter?.filterType.rawValue != filterViewModel.id
                        }
                        self.runPreload()
                    }
                }
            }
        }
    }

    private func buildCommonResetButtonClosureBuilder() {
        builder.commonResetButtonClosure = { [weak self] in
            guard let self = self else { return }

            State.DataType.allCases.forEach { type in
                switch type {
                case .extensionFilters:
                    self.resetModels(models: &self.tempState.filterModels)
                case .searchFilters:
                    self.resetModels(models: &self.tempState.searchFilterModels)
                }
            }

            self.runPreload()
        }
    }

    private func runPreload() {
        guard let provider = provider, let folder = folder else { return }

        currentLoading = true
        updateViewModel()

        let completion: (Int) -> Void = { [weak self] count in
            self?.tempState.itemsCount = count
            self?.currentLoading = false
            self?.updateViewModel()
        }

        let filterParams = makeFilterParams(state: tempState)
        provider.fetch(for: folder, parameters: ["filters": filterParams], completeon: { [weak self] provider, result, success, error in
            guard success else {
                completion(self?.tempState.itemsCount ?? 0)
                return
            }
            completion(provider.total)
        })
    }

    private func resetModels(models: inout [ASCDocumentsFilterModel]) {
        models.enumerated().forEach { index, _ in
            models[index].isSelected = false
        }
    }
}
