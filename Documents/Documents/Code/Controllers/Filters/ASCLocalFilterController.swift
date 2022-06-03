//
//  ASCLocalFilterController.swift
//  Documents
//
//  Created by Лолита Чернышева on 30.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCLocalFilterController {
    struct State {
        var filterModels: [ASCDocumentsFilterModel]
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
    private let filtersViewController: ASCFiltersViewController

    // MARK: - public properties

    var folder: ASCFolder?
    var provider: ASCFileProviderProtocol?
    var filtersParams: [String: Any]? {
        guard let appliedState = appliedState else { return nil }
        return makeFilterParams(state: appliedState)
    }

    var actionButtonTappedClousure: () -> Void = {}

    // MARK: - init

    init(builder: ASCFiltersCollectionViewModelBuilder, filtersViewController: ASCFiltersViewController, itemsCount: Int) {
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
        updateViewModel()
    }

    private func makeFilterParams(state: State) -> [String: Any] {
        let hasSelectedFilter = state.filterModels.map { $0.isSelected }.contains(true)
        var params: [String: Any] = [:]
        guard hasSelectedFilter else { return params }
        if let model = state.filterModels.first(where: { $0.isSelected }) {
            params["filterType"] = model.filterType.rawValue
        }
        return params
    }

    private func updateViewModel() {
        let viewModel = builder.buildViewModel(
            state: currentLoading ? .loading : .normal,
            filtersContainers: [
                .init(sectionName: FiltersSection.type.localizedString(), elements: tempState.filterModels),
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
        buildResetButtonClosureBuilder()
        builder.actionButtonClosure = { [weak self] in
            self?.appliedState = self?.tempState
            self?.actionButtonTappedClousure()
        }
    }

    private func buildDidSelectedClosure() {
        builder.didSelectedClosure = { [weak self] filterViewModel in
            guard let self = self else { return }

            let isFilterModelsContainsSelectedId: Bool = self.tempState.filterModels.map { $0.filterType.rawValue }.contains(filterViewModel.id)

            if isFilterModelsContainsSelectedId {
                let previousSelectedFilter = self.tempState.filterModels.first(where: { $0.isSelected })
                for (index, filterModel) in self.tempState.filterModels.enumerated() {
                    self.tempState.filterModels[index].isSelected = filterModel.filterType.rawValue == filterViewModel.id && previousSelectedFilter?.filterType.rawValue != filterViewModel.id
                }
                self.runPreload()
            }
        }
    }

    private func buildResetButtonClosureBuilder() {
        builder.resetButtonClosure = { [weak self] in
            guard let self = self else { return }
            for (index, _) in self.tempState.filterModels.enumerated() {
                self.tempState.filterModels[index].isSelected = false
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
}
