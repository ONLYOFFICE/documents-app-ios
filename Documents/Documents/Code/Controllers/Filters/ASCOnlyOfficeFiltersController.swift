//
//  ASCOnlyOfficeFiltersController.swift
//  Documents
//
//  Created by Лолита Чернышева on 05.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyOfficeFiltersController {
    private let builder: ASCFiltersCollectionViewModelBuilder
    private let filtersViewController: ASCFiltersViewController

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

    init(builder: ASCFiltersCollectionViewModelBuilder, filtersViewController: ASCFiltersViewController) {
        self.builder = builder
        self.filtersViewController = filtersViewController
        buildActions()
    }

    func updateViewModel() {
        let viewModel = builder.buildViewModel(filtersContainers: [
            .init(sectionName: FiltersSection.type.localizedString(), elements: filterModels),
            .init(sectionName: FiltersSection.author.localizedString(), elements: authorsModels),
        ],
        actionButtonTitle: "TODO")
        filtersViewController.viewModel = viewModel
    }

    private func buildActions() {
        builder.didSelectedClosure = { [weak self] filterViewModel in
            guard let self = self else { return }
            for (index, filterModel) in self.filterModels.enumerated() {
                self.filterModels[index].isSelected = filterModel.filterType.rawValue == filterViewModel.id
            }
            self.updateViewModel()
        }
    }
}
