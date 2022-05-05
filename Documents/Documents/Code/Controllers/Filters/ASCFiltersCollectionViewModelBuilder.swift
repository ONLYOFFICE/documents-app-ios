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
    var reserButtonClosure: () -> Void = {}
    var didSelectedClosure: (FilterViewModel) -> Void = { _ in }
    var didFilterResetBtnTapped: (FilterViewModel) -> Void = { _ in }

    func buildViewModel(filtersContainers: [FiltersContainer], actionButtonTitle: String) -> FiltersCollectionViewModel {
        let data: [ASCDocumentsSectionViewModel] = filtersContainers.map { filtersContainer in
            let filterViewModelList: [FilterViewModel] = filtersContainer.elements.map { $0.convert() }
            return ASCDocumentsSectionViewModel(sectionName: filtersContainer.sectionName, filters: filterViewModelList)
        }
        return FiltersCollectionViewModel(data: data,
                                          actionButtonTitle: actionButtonTitle,
                                          actionButtonClosure: actionButtonClosure,
                                          reserButtonClosure: reserButtonClosure,
                                          didSelectedClosure: didSelectedClosure,
                                          didFilterResetBtnTapped: didFilterResetBtnTapped)
    }
}
