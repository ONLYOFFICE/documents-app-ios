//
//  ASCDocSpaceRoomsFiltersController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 24/02/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCDocSpaceRoomsFiltersController: ASCDocSpaceFiltersController {
    required init(
        builder: ASCFiltersCollectionViewModelBuilder,
        filtersViewController: ASCFiltersViewController,
        itemsCount: Int
    ) {
        super.init(builder: builder, filtersViewController: filtersViewController, itemsCount: itemsCount)
        tempState = .defaultDocSpaceRoomsState(itemsCount)
        usersSectionTitle = FiltersSection.member.localizedString()
        buildActions()
    }

    override func prepareForDisplay(total: Int) {
        if let appliedState = appliedState {
            tempState = appliedState
        } else {
            tempState = .defaultDocSpaceRoomsState(total)
        }
        runPreload()
    }

    override func makeFilterParams(state: State) -> [String: Any] {
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
                params["type"] = model.filterType.filterValue
                return params
            case .thirdPartyResourceFilters:
                guard let model = state.thirdPartyResourceFilters.first(where: { $0.isSelected }) else { return params }
                params["provider"] = model.filterType.filterValue
                return params
            case .tags:
                guard let model = state.tagsFilters.first(where: { $0.isSelected }) else { return params }
                params["tags"] = model.filterType.filterValue
                return params
            }
        }
    }
}
