//
//  ASCOnlyOfficeFiltersController.swift
//  Documents
//
//  Created by Лолита Чернышева on 05.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCOnlyOfficeFiltersController: ASCFiltersControllerProtocol {
    struct State {
        enum DataType: CaseIterable {
            case extensionFilters
            case ownerFilters
            case searchFilters
        }

        var filterModels: [ASCDocumentsFilterModel]
        var authorsModels: [ActionFilterModel]
        var searchFilterModels: [ASCDocumentsFilterModel]
        var itemsCount: Int

        static var defaultState: (Int) -> State = { count in
            State(filterModels: defaultFilterModel,
                  authorsModels: defaultAuthorsModels,
                  searchFilterModels: searchFilterModels,
                  itemsCount: count)
        }

        static var recentlyCategoryDefaultState: (Int) -> State = { count in
            State(filterModels: defaultFilterModel.filter { $0.filterType != .folders },
                  authorsModels: defaultAuthorsModels,
                  searchFilterModels: searchFilterModels,
                  itemsCount: count)
        }

        static let defaultFilterModel = [
            ASCDocumentsFilterModel(filterName: FiltersName.folders.localizedString(), isSelected: false, filterType: .folders),
            ASCDocumentsFilterModel(filterName: FiltersName.documents.localizedString(), isSelected: false, filterType: .documents),
            ASCDocumentsFilterModel(filterName: FiltersName.presentations.localizedString(), isSelected: false, filterType: .presentations),
            ASCDocumentsFilterModel(filterName: FiltersName.spreadsheets.localizedString(), isSelected: false, filterType: .spreadsheets),
            ASCDocumentsFilterModel(filterName: FiltersName.images.localizedString(), isSelected: false, filterType: .images),
            ASCDocumentsFilterModel(filterName: FiltersName.media.localizedString(), isSelected: false, filterType: .media),
            ASCDocumentsFilterModel(filterName: FiltersName.archives.localizedString(), isSelected: false, filterType: .archive),
            ASCDocumentsFilterModel(filterName: FiltersName.allFiles.localizedString(), isSelected: false, filterType: .files),
        ]

        static let defaultAuthorsModels = [
            ActionFilterModel(defaultName: FiltersName.users.localizedString(), selectedName: nil, filterType: .user),
            ActionFilterModel(defaultName: FiltersName.groups.localizedString(), selectedName: nil, filterType: .group),
        ]

        static let searchFilterModels = [ASCDocumentsFilterModel(filterName: FiltersName.excludeSubfolders.localizedString(), isSelected: false, filterType: .excludeSubfolders)]
    }

    // MARK: -  state

    private var tempState: State
    private var appliedState: State?

    // MARK: -  properties

    private var currentSelectedAuthorFilterType: ApiFilterType?
    private let builder: ASCFiltersCollectionViewModelBuilder
    private var currentLoading = false

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

    private var isRecentCategory: Bool {
        folder?.rootFolderType == .onlyofficeRecent
    }

    private var allowSearchFilter: Bool {
        guard let onlyofficeProvider = provider as? ASCOnlyofficeProvider else { return false }
        let isRecentCategory = folder?.rootFolderType == .onlyofficeRecent
        let isServerVersionCorrect = onlyofficeProvider.apiClient.serverVersion?.community?.isVersion(greaterThanOrEqualTo: "12.0.1") == true
        return !isRecentCategory && isServerVersionCorrect
    }

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
            tempState = getDefaultState(total)
        }
        runPreload()
    }

    func getDefaultState(_ total: Int) -> State {
        guard !isRecentCategory else { return .recentlyCategoryDefaultState(total) }
        return .defaultState(total)
    }

    private func hasSelectedFilter(state: State) -> Bool {
        var result = false
        State.DataType.allCases.forEach { type in
            switch type {
            case .extensionFilters:
                result = result || state.filterModels.map { $0.isSelected }.contains(true)
            case .ownerFilters:
                result = result || state.authorsModels.compactMap { $0.selectedName }.count > 0
            case .searchFilters:
                result = result || state.searchFilterModels.map { $0.isSelected }.contains(true)
            }
        }
        return result
    }

    private func makeFilterParams(state: State) -> [String: Any] {
        var params: [String: Any] = ["withSubfolders": "true"]
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
                        params["withSubfolders"] = "false"
                    default:
                        log.error("UnsuppurtedFIlterType: \(model.filterType.rawValue)")
                    }
                }
            case .ownerFilters:
                if let model = state.authorsModels.first(where: { $0.selectedName != nil }),
                   let id = model.id
                {
                    params["userIdOrGroupId"] = id
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
                .init(sectionName: FiltersSection.author.localizedString(), elements: tempState.authorsModels),
                allowSearchFilter ? .init(sectionName: FiltersSection.search.localizedString(), elements: tempState.searchFilterModels) : nil,
            ].compactMap { $0 },
            actionButtonViewModel: tempState.itemsCount > 0
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
        builder.didFilterResetBtnTapped = { [weak self] filterViewModel in
            guard let self = self else { return }
            State.DataType.allCases.forEach { type in
                switch type {
                case .extensionFilters, .searchFilters: break
                case .ownerFilters:
                    if let index = self.tempState.authorsModels.firstIndex(where: { $0.filterType.rawValue == filterViewModel.id }) {
                        self.resetAuthorModel(index: index)
                        self.runPreload()
                    }
                }
            }
        }
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
                case .ownerFilters:
                    let isAthorModelsContainsSelectedId: Bool = self.tempState.authorsModels.map { $0.filterType.rawValue }.contains(filterViewModel.id)

                    if isAthorModelsContainsSelectedId {
                        let selectedIdClosure: (ApiFilterType?) -> String? = { [weak self] type in
                            switch type {
                            case .user: return self?.tempState.authorsModels.first(where: { $0.filterType == .user })?.id
                            case .group: return self?.tempState.authorsModels.first(where: { $0.filterType == .group })?.id
                            default: return nil
                            }
                        }

                        switch ApiFilterType(rawValue: filterViewModel.id) {
                        case .user:
                            self.selectUserViewController.markAsSelected(id: selectedIdClosure(.user))
                            let navigationVC = UINavigationController(rootASCViewController: self.selectUserViewController)
                            ASCViewControllerManager.shared.topViewController?.navigationController?.present(navigationVC, animated: true)
                            self.currentSelectedAuthorFilterType = .user
                        case .group:
                            self.selectGroupViewController.markAsSelected(id: selectedIdClosure(.group))
                            let navigationVC = UINavigationController(rootASCViewController: self.selectGroupViewController)
                            ASCViewControllerManager.shared.topViewController?.navigationController?.present(navigationVC, animated: true)
                            self.currentSelectedAuthorFilterType = .group
                        default: return
                        }
                        self.updateViewModel()
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
                case .ownerFilters:
                    self.resetAuthorModels()
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

    private func resetAuthorModels() {
        tempState.authorsModels.enumerated().forEach { index, _ in
            resetAuthorModel(index: index)
        }
    }

    private func resetAuthorModel(index: Int) {
        tempState.authorsModels[index].selectedName = nil
        tempState.authorsModels[index].id = nil
    }

    private func resetModels(models: inout [ASCDocumentsFilterModel]) {
        models.enumerated().forEach { index, _ in
            models[index].isSelected = false
        }
    }
}

extension ASCOnlyOfficeFiltersController: ASCFiltersViewControllerDelegate {
    func updateData(filterText itemText: String, id: String?) {
        resetAuthorModels()
        switch currentSelectedAuthorFilterType {
        case .user, .group:
            if let index = tempState.authorsModels.firstIndex(where: { $0.filterType == currentSelectedAuthorFilterType }) {
                tempState.authorsModels[index].selectedName = itemText
                tempState.authorsModels[index].id = id
            }
        default: break
        }

        currentSelectedAuthorFilterType = nil
        runPreload()
    }
}
