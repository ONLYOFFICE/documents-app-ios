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
    struct State {
        enum DataType: CaseIterable {
            case memberFilters
            case roomTypeFilters
            case thirdPartyResourceFilters
        }

        var meFilter: ASCDocumentsFilterModel
        var memberFilter: ActionFilterModel
        var hasSelectedMember: Bool { memberFilter.selectedName != nil && memberFilter.selectedName?.isEmpty == false }
        var roomTypeFilters: [ASCDocumentsFilterModel]
        var thirdPartyResourceFilters: [ASCDocumentsFilterModel]

        var itemsCount: Int

        static var defaultDocSpaceState: (Int) -> State = { count in
            State(meFilter: meFilter,
                  memberFilter: memberFilter,
                  roomTypeFilters: docTypeFilters,
                  thirdPartyResourceFilters: [],
                  itemsCount: count)
        }

        static var defaultDocSpaceRoomsState: (Int) -> State = { count in
            State(meFilter: meFilter,
                  memberFilter: memberFilter,
                  roomTypeFilters: roomTypeFilters,
                  thirdPartyResourceFilters: [],
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
            ASCDocumentsFilterModel(filterName: FiltersName.googleDrive.localizedString(), isSelected: false, filterType: .googleDrive),
            ASCDocumentsFilterModel(filterName: FiltersName.oneDrive.localizedString(), isSelected: false, filterType: .oneDrive),
            ASCDocumentsFilterModel(filterName: FiltersName.box.localizedString(), isSelected: false, filterType: .box),
        ]
    }

    // MARK: -  state

    var tempState: State
    var appliedState: State?

    // MARK: -  properties

    var currentSelectedAuthorFilterType: ApiFilterType?
    var builder: ASCFiltersCollectionViewModelBuilder
    var currentLoading = false

    var usersSectionTitle = FiltersSection.author.localizedString()

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
                return state.roomTypeFilters.map { $0.isSelected }.contains(true)
            case .thirdPartyResourceFilters:
                return state.thirdPartyResourceFilters.map { $0.isSelected }.contains(true)
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
            case .thirdPartyResourceFilters: return params
            }
        }
    }

    func updateViewModel() {
        let usersFilters: [FilterTypeConvirtable] = tempState.hasSelectedMember ? [tempState.memberFilter] : [tempState.meFilter, tempState.memberFilter]
        let viewModel = builder.buildViewModel(
            state: currentLoading ? .loading : .normal,
            filtersContainers: [
                .init(sectionName: usersSectionTitle, elements: usersFilters),
                .init(sectionName: FiltersSection.type.localizedString(), elements: tempState.roomTypeFilters),
                tempState.thirdPartyResourceFilters.isEmpty ? nil : .init(sectionName: FiltersSection.thirdPartyResource.localizedString(), elements: tempState.thirdPartyResourceFilters),
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

    func buildActions() {
        buildDidSelectedClosure()
        buildCommonResetButtonClosureBuilder()
        builder.didFilterResetBtnTapped = { [weak self] filterViewModel in
            guard let self = self else { return }
            for type in State.DataType.allCases {
                switch type {
                case .roomTypeFilters, .thirdPartyResourceFilters: break
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

    private func buildDidSelectedClosure() {
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
                }
            }
        }
    }

    private func buildCommonResetButtonClosureBuilder() {
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
                }
            }

            self.runPreload()
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

    private func resetAuthorModels() {
        tempState.meFilter.isSelected = false
        resetAuthorModel()
    }

    private func resetAuthorModel() {
        tempState.memberFilter.selectedName = nil
        tempState.memberFilter.id = nil
    }

    private func resetModels(models: inout [ASCDocumentsFilterModel]) {
        for (index, _) in models.enumerated() {
            models[index].isSelected = false
        }
    }
}

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
