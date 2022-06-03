//
//  ASCFiltersCollectionViewModelBuilder.swift
//  Documents
//
//  Created by Лолита Чернышева on 05.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

struct FiltersContainer {
    var sectionName: String
    var elements: [FilterTypeConvirtable]
}

class ASCFiltersCollectionViewModelBuilder {
    var actionButtonClosure: () -> Void = {}
    var resetButtonClosure: () -> Void = {}
    var didSelectedClosure: (FilterViewModel) -> Void = { _ in }
    var didFilterResetBtnTapped: (FilterViewModel) -> Void = { _ in }
    var actionButtonTitle: ActionButtonViewModel = .empty

    func buildViewModel(state: FiltersCollectionViewModel.State,
                        filtersContainers: [FiltersContainer],
                        actionButtonViewModel: ActionButtonViewModel) -> FiltersCollectionViewModel
    {
        let data: [ASCDocumentsSectionViewModel] = filtersContainers.map { filtersContainer in
            let filterViewModelList: [FilterViewModel] = filtersContainer.elements.map { $0.convert() }
            return ASCDocumentsSectionViewModel(sectionName: filtersContainer.sectionName, filters: filterViewModelList)
        }
        return FiltersCollectionViewModel(state: state,
                                          data: data,
                                          actionButtonViewModel: actionButtonViewModel,
                                          actionButtonClosure: actionButtonClosure,
                                          resetButtonClosure: resetButtonClosure,
                                          didSelectedClosure: didSelectedClosure,
                                          didFilterResetBtnTapped: didFilterResetBtnTapped)
    }
}
