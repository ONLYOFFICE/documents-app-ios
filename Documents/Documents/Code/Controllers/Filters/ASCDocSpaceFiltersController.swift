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

        var memberFilters: [ActionFilterModel]
        var roomTypeFilters: [ASCDocumentsFilterModel]
        var thirdPartyResourceFilters: [ASCDocumentsFilterModel]

        var itemsCount: Int

        static var defaultState: (Int) -> State = { count in
            State(memberFilters: [ActionFilterModel(defaultName: FiltersName.users.localizedString(), selectedName: nil, filterType: .user)],
                  roomTypeFilters: [
                      ASCDocumentsFilterModel(filterName: FiltersName.customRoom.localizedString(), isSelected: false, filterType: .customRoom),
                      ASCDocumentsFilterModel(filterName: FiltersName.fillingFormRoom.localizedString(), isSelected: false, filterType: .fillingFormRoom),
                      ASCDocumentsFilterModel(filterName: FiltersName.collaborationRoom.localizedString(), isSelected: false, filterType: .collaborationRoom),
                      ASCDocumentsFilterModel(filterName: FiltersName.reviewRoom.localizedString(), isSelected: false, filterType: .reviewRoom),
                      ASCDocumentsFilterModel(filterName: FiltersName.viewOnlyRoom.localizedString(), isSelected: false, filterType: .viewOnlyRoom),
                  ],
                  thirdPartyResourceFilters: [
                      ASCDocumentsFilterModel(filterName: FiltersName.dropBox.localizedString(), isSelected: false, filterType: .dropBox),
                      ASCDocumentsFilterModel(filterName: FiltersName.googleDrive.localizedString(), isSelected: false, filterType: .googleDrive),
                      ASCDocumentsFilterModel(filterName: FiltersName.oneDrive.localizedString(), isSelected: false, filterType: .oneDrive),
                      ASCDocumentsFilterModel(filterName: FiltersName.box.localizedString(), isSelected: false, filterType: .box),
                  ],
                  itemsCount: count)
        }

        static let defaultAuthorsModels = [
            ActionFilterModel(defaultName: FiltersName.users.localizedString(), selectedName: nil, filterType: .user),
            ActionFilterModel(defaultName: FiltersName.groups.localizedString(), selectedName: nil, filterType: .group),
        ]
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
        State.DataType.allCases.reduce(false) { hasSelected, dataType in
            guard !hasSelected else { return hasSelected }
            switch dataType {
            case .memberFilters:
                return state.memberFilters.compactMap { $0.selectedName }.count > 0
            case .roomTypeFilters:
                return state.roomTypeFilters.map { $0.isSelected }.contains(true)
            case .thirdPartyResourceFilters:
                return state.thirdPartyResourceFilters.map { $0.isSelected }.contains(true)
            }
        }
    }

    private func makeFilterParams(state: State) -> [String: Any] {
        return State.DataType.allCases.reduce([String: Any]()) { params, dataType in
            var params = params
            switch dataType {
            case .memberFilters:
                guard let model = state.memberFilters.first(where: { $0.selectedName != nil }), let id = model.id else { return params }
                params["userIdOrGroupId"] = id
                return params
            case .roomTypeFilters:
                guard let model = state.roomTypeFilters.first(where: { $0.isSelected }) else { return params }
                params["type"] = model.filterType.filterValue
                return params
            case .thirdPartyResourceFilters:
                guard let model = state.thirdPartyResourceFilters.first(where: { $0.isSelected }) else { return params }
                params["provider"] = model.filterType.filterValue
                return params
            }
        }
    }

    private func updateViewModel() {
        let viewModel = builder.buildViewModel(
            state: currentLoading ? .loading : .normal,
            filtersContainers: [
                .init(sectionName: FiltersSection.member.localizedString(), elements: tempState.memberFilters),
                .init(sectionName: FiltersSection.type.localizedString(), elements: tempState.roomTypeFilters),
                .init(sectionName: FiltersSection.thirdPartyResource.localizedString(), elements: tempState.thirdPartyResourceFilters),
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
                case .roomTypeFilters, .thirdPartyResourceFilters: break
                case .memberFilters:
                    if let index = self.tempState.memberFilters.firstIndex(where: { $0.filterType.rawValue == filterViewModel.id }) {
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
                    let isAthorModelsContainsSelectedId: Bool = self.tempState.memberFilters.map { $0.filterType.rawValue }.contains(filterViewModel.id)

                    if isAthorModelsContainsSelectedId {
                        let selectedIdClosure: (ApiFilterType?) -> String? = { [weak self] type in
                            switch type {
                            case .user: return self?.tempState.memberFilters.first(where: { $0.filterType == .user })?.id
                            case .group: return self?.tempState.memberFilters.first(where: { $0.filterType == .group })?.id
                            default: return nil
                            }
                        }

                        switch ApiFilterType(rawValue: filterViewModel.id) {
                        case .user:
                            self.selectUserViewController.markAsSelected(id: selectedIdClosure(.user))
                            let navigationVC = UINavigationController(rootASCViewController: self.selectUserViewController)
                            ASCViewControllerManager.shared.topViewController?.navigationController?.present(navigationVC, animated: true)
                            self.currentSelectedAuthorFilterType = .user
                        default: return
                        }
                        self.updateViewModel()
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

            State.DataType.allCases.forEach { type in
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
        tempState.memberFilters.enumerated().forEach { index, _ in
            resetAuthorModel(index: index)
        }
    }

    private func resetAuthorModel(index: Int) {
        tempState.memberFilters[index].selectedName = nil
        tempState.memberFilters[index].id = nil
    }

    private func resetModels(models: inout [ASCDocumentsFilterModel]) {
        models.enumerated().forEach { index, _ in
            models[index].isSelected = false
        }
    }
}

extension ASCDocSpaceFiltersController: ASCFiltersViewControllerDelegate {
    func updateData(filterText itemText: String, id: String?) {
        resetAuthorModels()
        switch currentSelectedAuthorFilterType {
        case .user:
            if let index = tempState.memberFilters.firstIndex(where: { $0.filterType == currentSelectedAuthorFilterType }) {
                tempState.memberFilters[index].selectedName = itemText
                tempState.memberFilters[index].id = id
            }
        default: break
        }

        currentSelectedAuthorFilterType = nil
        runPreload()
    }
}
