//
//  ASCOnlyOfficeFiltersController.swift
//  Documents
//
//  Created by Лолита Чернышева on 05.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCOnlyOfficeFiltersController {
    struct State {
        var filterModels: [ASCDocumentsFilterModel]
        var authorsModels: [ActionFilterModel]
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
            authorsModels: [
                ActionFilterModel(defaultName: FiltersName.users.localizedString(), selectedName: nil, filterType: .user),
                ActionFilterModel(defaultName: FiltersName.groups.localizedString(), selectedName: nil, filterType: .group),
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
        let hasSelectedFilter = state.filterModels.map { $0.isSelected }.contains(true) || state.authorsModels.compactMap { $0.selectedName }.count > 0
        var params: [String: Any] = [:]
        guard hasSelectedFilter else { return params }
        if let model = state.filterModels.first(where: { $0.isSelected }) {
            params["filterType"] = model.filterType.rawValue
        }
        if let model = state.authorsModels.first(where: { $0.selectedName != nil }),
           let id = model.id
        {
            params["userIdOrGroupId"] = id
        }
        return params
    }

    private func updateViewModel() {
        let viewModel = builder.buildViewModel(
            state: currentLoading ? .loading : .normal,
            filtersContainers: [
                .init(sectionName: FiltersSection.type.localizedString(), elements: tempState.filterModels),
                .init(sectionName: FiltersSection.author.localizedString(), elements: tempState.authorsModels),
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
        builder.didFilterResetBtnTapped = { [weak self] filterViewModel in
            guard let self = self else { return }
            if let index = self.tempState.authorsModels.firstIndex(where: { $0.filterType.rawValue == filterViewModel.id }) {
                self.resetAuthorModel(index: index)
                self.runPreload()
            }
        }
        builder.actionButtonClosure = { [weak self] in
            self?.appliedState = self?.tempState
            self?.actionButtonTappedClousure()
        }
    }

    private func buildDidSelectedClosure() {
        builder.didSelectedClosure = { [weak self] filterViewModel in
            guard let self = self else { return }

            let isFilterModelsContainsSelectedId: Bool = self.tempState.filterModels.map { $0.filterType.rawValue }.contains(filterViewModel.id)
            let isAthorModelsContainsSelectedId: Bool = self.tempState.authorsModels.map { $0.filterType.rawValue }.contains(filterViewModel.id)

            if isFilterModelsContainsSelectedId {
                let previousSelectedFilter = self.tempState.filterModels.first(where: { $0.isSelected })
                for (index, filterModel) in self.tempState.filterModels.enumerated() {
                    self.tempState.filterModels[index].isSelected = filterModel.filterType.rawValue == filterViewModel.id && previousSelectedFilter?.filterType.rawValue != filterViewModel.id
                }
                self.runPreload()
            }

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
        }
    }

    private func buildResetButtonClosureBuilder() {
        builder.resetButtonClosure = { [weak self] in
            guard let self = self else { return }

            for (index, _) in self.tempState.filterModels.enumerated() {
                self.tempState.filterModels[index].isSelected = false
            }

            self.resetAuthorModels()
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
