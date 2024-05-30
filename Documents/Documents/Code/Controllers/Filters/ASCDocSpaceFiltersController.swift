//
//  ASCDocSpaceFiltersController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 8/12/22.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

class ASCDocSpaceFiltersController: ASCFiltersControllerProtocol {
    
    // MARK: Public vars
    
    var tempState: State
    var usersSectionTitle = FiltersSection.author.localizedString()

    var folder: ASCFolder?
    var provider: ASCFileProviderProtocol?
    var filtersViewController: ASCFiltersViewController
    var filtersParams: [String: Any]? {
        guard let appliedState = appliedState else { return nil }
        return makeFilterParams(state: appliedState)
    }

    var isReset: Bool {
        guard let appliedState = appliedState else { return true }
        return !hasSelectedFilter(state: appliedState)
    }

    var onAction: () -> Void = {}
    
    // MARK: Private vars
    
    private(set) var appliedState: State?
    private var currentSelectedAuthorFilterType: ApiFilterType?
    private var currentLoading = false
    
    private var builder: ASCFiltersCollectionViewModelBuilder

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

    // MARK: - init

    required init(
        builder: ASCFiltersCollectionViewModelBuilder,
        filtersViewController: ASCFiltersViewController,
        itemsCount: Int
    ) {
        self.builder = builder
        self.filtersViewController = filtersViewController
        tempState = .defaultDocSpaceState(itemsCount)
        buildActions()
    }

    func prepareForDisplay(total: Int) {
        if let appliedState = appliedState {
            tempState = appliedState
        } else {
            tempState = .defaultDocSpaceState(total)
        }
        runPreload()
    }

    private func hasSelectedFilter(state: State) -> Bool {
        State.DataType.allCases.reduce(false) { hasSelected, dataType in
            guard !hasSelected else { return hasSelected }
            switch dataType {
            case .memberFilters:
                return state.memberFilter.selectedName?.isEmpty == false || state.meFilter.isSelected
            case .roomTypeFilters:
                return state.roomTypeFilters.contains(where: { $0.isSelected })
            case .tags:
                return state.tagsFilters.contains(where: { $0.isSelected })
            case .thirdPartyResourceFilters:
                return state.thirdPartyResourceFilters.contains(where: { $0.isSelected })
            }
        }
    }

    func makeFilterParams(state: State) -> [String: Any] {
        return State.DataType.allCases.reduce([String: Any]()) { params, dataType in
            var params = params
            switch dataType {
            case .memberFilters:
                let userId: String? = {
                    guard let id = state.memberFilter.id else {
                        return state.meFilter.isSelected ? ASCFileManager.onlyofficeProvider?.user?.userId : nil
                    }
                    return id
                }()
                guard let id = userId else { return params }
                params["userIdOrGroupId"] = id
                return params
            case .roomTypeFilters:
                guard let model = state.roomTypeFilters.first(where: { $0.isSelected }) else { return params }
                params["filterType"] = model.filterType.filterValue
                return params
            case .tags:
                guard let selectedTagsValue = selectedTagsValues(state: state) else { return params }
                params["tags"] = selectedTagsValue
                return params
            case .thirdPartyResourceFilters: return params
            }
        }
    }

    func updateViewModel() {
        
        let viewModel = builder.buildViewModel(
            state: currentLoading ? .loading : .normal,
            filtersContainers: buildFilterContainers(),
            actionButtonViewModel: buildActionButtonViewModel()
        )
        filtersViewController.viewModel = viewModel
    }
    
    func buildActions() {
        buildDidSelectedClosure()
        buildCommonResetButtonClosureBuilder()
        builder.didFilterResetBtnTapped = { [weak self] filterViewModel in
            guard let self = self else { return }
            for type in State.DataType.allCases {
                switch type {
                case .roomTypeFilters, .thirdPartyResourceFilters, .tags: break
                case .memberFilters:
                    self.resetAuthorModels()
                    self.runPreload()
                }
            }
        }
        builder.actionButtonClosure = { [weak self] in
            self?.appliedState = self?.tempState
            self?.onAction()
        }
    }

    func runPreload() {
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

// MARK: - Private methods

private extension ASCDocSpaceFiltersController {
    
    // MARK: Build
    
    func buildActionButtonViewModel() -> ActionButtonViewModel {
        tempState.itemsCount > 0
            ? ActionButtonViewModel(text: String.localizedStringWithFormat(NSLocalizedString("Show %d results", comment: ""), tempState.itemsCount),
                                    backgroundColor: Asset.Colors.filterCapsule.color,
                                    textColor: Asset.Colors.brend.color,
                                    isActive: true)
            : ActionButtonViewModel(text: NSLocalizedString("Nothing to show", comment: ""),
                                    backgroundColor: Asset.Colors.filterCapsule.color,
                                    textColor: Asset.Colors.tableCellSeparator.color,
                                    isActive: false)
    }
    
    func buildFilterContainers() -> [FiltersContainer] {
        [
            buildUserFilterContainer(),
            buildTypeContainer(),
            buildTagsContainer(),
            buildThirdPartyContainer(),
        ].compactMap { $0 }
    }
    
    func buildUserFilterContainer() -> FiltersContainer {
        let usersFilters: [FilterTypeConvirtable] = tempState.hasSelectedMember ? [tempState.memberFilter] : [tempState.meFilter, tempState.memberFilter]
        return FiltersContainer(
            sectionName: usersSectionTitle,
            elements: usersFilters
        )
    }
    
    func buildTypeContainer() -> FiltersContainer {
        FiltersContainer(
            sectionName: FiltersSection.type.localizedString(),
            elements: tempState.roomTypeFilters
        )
    }
    
    func buildTagsContainer() -> FiltersContainer? {
        tempState.tagsFilters.isEmpty
        ? nil
        : FiltersContainer(
            sectionName: FiltersSection.tags.localizedString(),
            elements: tempState.tagsFilters
        )
    }
    
    func buildThirdPartyContainer() -> FiltersContainer? {
        tempState.thirdPartyResourceFilters.isEmpty
        ? nil
        : FiltersContainer(
            sectionName: FiltersSection.thirdPartyResource.localizedString(),
            elements: tempState.thirdPartyResourceFilters
        )
    }
    
    func buildDidSelectedClosure() {
        builder.didSelectedClosure = { [weak self] filterViewModel in
            guard let self = self else { return }

            for type in State.DataType.allCases {
                switch type {
                case .roomTypeFilters:
                    let isFilterModelsContainsSelectedId: Bool = self.tempState.roomTypeFilters.map { $0.filterType.rawValue }.contains(filterViewModel.id)

                    if isFilterModelsContainsSelectedId {
                        let previousSelectedFilter = self.tempState.roomTypeFilters.first(where: { $0.isSelected })
                        for (index, filterModel) in self.tempState.roomTypeFilters.enumerated() {
                            self.tempState.roomTypeFilters[index].isSelected = filterModel.filterType.rawValue == filterViewModel.id && previousSelectedFilter?.filterType.rawValue != filterViewModel.id
                        }
                        self.runPreload()
                    }
                case .memberFilters:
                    let isAthorModelsContainsSelectedId: Bool = self.tempState.memberFilter.filterType.rawValue == filterViewModel.id

                    if isAthorModelsContainsSelectedId {
                        let selectedIdClosure: (ApiFilterType?) -> String? = { [weak self] type in
                            switch type {
                            case .user: return self?.tempState.memberFilter.id
                            default: return nil
                            }
                        }

                        switch ApiFilterType(rawValue: filterViewModel.id) {
                        case .user:
                            self.selectUserViewController.markAsSelected(id: selectedIdClosure(.user))
                            let navigationVC = UINavigationController(rootASCViewController: self.selectUserViewController)
                            ASCViewControllerManager.shared.topViewController?.navigationController?.present(navigationVC, animated: true)
                            self.currentSelectedAuthorFilterType = .user
                        default: continue
                        }
                        self.updateViewModel()
                    } else if self.tempState.meFilter.filterType.rawValue == filterViewModel.id {
                        self.tempState.meFilter.isSelected.toggle()
                        self.runPreload()
                    }
                case .thirdPartyResourceFilters:
                    let isFilterModelsContainsSelectedId: Bool = self.tempState.thirdPartyResourceFilters.map { $0.filterType.rawValue }.contains(filterViewModel.id)

                    if isFilterModelsContainsSelectedId {
                        let previousSelectedFilter = self.tempState.thirdPartyResourceFilters.first(where: { $0.isSelected })
                        for (index, filterModel) in self.tempState.thirdPartyResourceFilters.enumerated() {
                            self.tempState.thirdPartyResourceFilters[index].isSelected = filterModel.filterType.rawValue == filterViewModel.id && previousSelectedFilter?.filterType.rawValue != filterViewModel.id
                        }
                        self.runPreload()
                    }
                case .tags:
                    if let tappedTagIndex: Int = tempState.tagsFilters.firstIndex(where: { $0.filterType.rawValue == filterViewModel.id }) {
                        tempState.tagsFilters[tappedTagIndex].isSelected.toggle()
                        self.runPreload()
                    }
                }
            }
        }
    }

    func buildCommonResetButtonClosureBuilder() {
        builder.commonResetButtonClosure = { [weak self] in
            guard let self = self else { return }

            for type in State.DataType.allCases {
                switch type {
                case .roomTypeFilters:
                    self.resetModels(models: &self.tempState.roomTypeFilters)
                case .memberFilters:
                    self.resetAuthorModels()
                case .thirdPartyResourceFilters:
                    self.resetModels(models: &self.tempState.thirdPartyResourceFilters)
                case .tags:
                    self.resetTagsModel()
                }
            }

            self.runPreload()
        }
    }
    
    // MARK: Reset methods

    private func resetAuthorModels() {
        tempState.meFilter.isSelected = false
        resetAuthorModel()
    }

    private func resetAuthorModel() {
        tempState.memberFilter.selectedName = nil
        tempState.memberFilter.id = nil
    }

    private func resetTagsModel() {
        for (i, _) in tempState.tagsFilters.enumerated() {
            tempState.tagsFilters[i].isSelected = false
        }
    }

    private func resetModels(models: inout [ASCDocumentsFilterModel]) {
        for (index, _) in models.enumerated() {
            models[index].isSelected = false
        }
    }
}

// MARK: - ASCFiltersViewControllerDelegate

extension ASCDocSpaceFiltersController: ASCFiltersViewControllerDelegate {
    func updateData(filterText itemText: String, id: String?) {
        resetAuthorModels()
        switch currentSelectedAuthorFilterType {
        case .user:
            tempState.memberFilter.selectedName = itemText
            tempState.memberFilter.id = id
        default: break
        }

        currentSelectedAuthorFilterType = nil
        runPreload()
    }
}

extension ASCDocSpaceFiltersController {
    func selectedTagsValues(state: State) -> String? {
        let selectedTags = state.tagsFilters.filter { $0.isSelected }
        guard !selectedTags.isEmpty else { return nil }
        return "[\"\(selectedTags.map { $0.filterType.filterValue }.joined(separator: "\",\""))\"]"
    }
}

// MARK: - State

extension ASCDocSpaceFiltersController {
    struct State {
        enum DataType: CaseIterable {
            case memberFilters
            case roomTypeFilters
            case thirdPartyResourceFilters
            case tags
        }

        var meFilter: ASCDocumentsFilterModel
        var memberFilter: ActionFilterModel
        var hasSelectedMember: Bool { memberFilter.selectedName != nil && memberFilter.selectedName?.isEmpty == false }
        var roomTypeFilters: [ASCDocumentsFilterModel]
        var thirdPartyResourceFilters: [ASCDocumentsFilterModel]
        var tagsFilters: [ASCDocumentsFilterModel]

        var itemsCount: Int

        static var defaultDocSpaceState: (Int) -> State = { count in
            State(meFilter: meFilter,
                  memberFilter: memberFilter,
                  roomTypeFilters: docTypeFilters,
                  thirdPartyResourceFilters: [],
                  tagsFilters: [],
                  itemsCount: count)
        }

        static var defaultDocSpaceRoomsState: (Int, [String]) -> State = { count, tags in
            State(meFilter: meFilter,
                  memberFilter: memberFilter,
                  roomTypeFilters: roomTypeFilters,
                  thirdPartyResourceFilters: thirdPartyResourceFilters,
                  tagsFilters: tags.map { ASCDocumentsFilterModel(filterName: $0, isSelected: false, filterType: .tag($0)) },
                  itemsCount: count)
        }

        private static let meFilter = ASCDocumentsFilterModel(filterName: FiltersName.me.localizedString(), isSelected: false, filterType: .me)
        private static let memberFilter = ActionFilterModel(defaultName: FiltersName.users.localizedString(), selectedName: nil, filterType: .user)

        private static let roomTypeFilters = [
            ASCDocumentsFilterModel(filterName: FiltersName.customRoom.localizedString(), isSelected: false, filterType: .customRoom),
            ASCDocumentsFilterModel(filterName: FiltersName.collaborationRoom.localizedString(), isSelected: false, filterType: .collaborationRoom),
            ASCDocumentsFilterModel(filterName: FiltersName.publicRoom.localizedString(), isSelected: false, filterType: .publicRoom),
        ]

        private static let docTypeFilters = [
            ASCDocumentsFilterModel(filterName: FiltersName.folders.localizedString(), isSelected: false, filterType: .folders),
            ASCDocumentsFilterModel(filterName: FiltersName.documents.localizedString(), isSelected: false, filterType: .documents),
            ASCDocumentsFilterModel(filterName: FiltersName.presentations.localizedString(), isSelected: false, filterType: .presentations),
            ASCDocumentsFilterModel(filterName: FiltersName.spreadsheets.localizedString(), isSelected: false, filterType: .spreadsheets),
            ASCDocumentsFilterModel(filterName: FiltersName.formTemplates.localizedString(), isSelected: false, filterType: .formTemplates),
            ASCDocumentsFilterModel(filterName: FiltersName.forms.localizedString(), isSelected: false, filterType: .forms),
            ASCDocumentsFilterModel(filterName: FiltersName.images.localizedString(), isSelected: false, filterType: .images),
            ASCDocumentsFilterModel(filterName: FiltersName.media.localizedString(), isSelected: false, filterType: .media),
            ASCDocumentsFilterModel(filterName: FiltersName.archives.localizedString(), isSelected: false, filterType: .archive),
            ASCDocumentsFilterModel(filterName: FiltersName.allFiles.localizedString(), isSelected: false, filterType: .files),
        ]

        private static let thirdPartyResourceFilters = [
            ASCDocumentsFilterModel(filterName: FiltersName.dropBox.localizedString(), isSelected: false, filterType: .dropBox),
            ASCDocumentsFilterModel(filterName: FiltersName.nextCloud.localizedString(), isSelected: false, filterType: .nextCloud),
            ASCDocumentsFilterModel(filterName: FiltersName.googleDrive.localizedString(), isSelected: false, filterType: .googleDrive),
            ASCDocumentsFilterModel(filterName: FiltersName.oneDrive.localizedString(), isSelected: false, filterType: .oneDrive),
            ASCDocumentsFilterModel(filterName: FiltersName.box.localizedString(), isSelected: false, filterType: .box),
        ]
    }
}
