//
//  ASCOnlyofficeDocSpaceCategoriesGroper.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 9.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeDocSpaceCategoriesGroper: ASCOnlyofficeCategoriesGrouper {
    func group(categories: [ASCOnlyofficeCategory]) -> ASCOnlyofficeCategoriesGroup {
        var roomsGroup: ASCOnlyofficeCategoriesGroup.TitledGroup = (title: NSLocalizedString("Rooms", comment: "DocSpace rooms"),
                                                                    categories: [])
        var filesGroup: ASCOnlyofficeCategoriesGroup.TitledGroup = (title: NSLocalizedString("Files", comment: ""),
                                                                    categories: [])
        var otherGroup: ASCOnlyofficeCategoriesGroup.TitledGroup = (title: " ", categories: [])

        for category in categories {
            switch category.folder?.rootFolderType {
            case .onlyofficeUser:
                roomsGroup.categories.append(category)
            case .onlyofficeFavorites, .onlyofficeRecent, .onlyofficeTrash:
                filesGroup.categories.append(category)
            default:
                category.isDocSpaceRoom
                    ? roomsGroup.categories.append(category)
                    : otherGroup.categories.append(category)
            }
        }
        return .titledGroups([roomsGroup,
                              filesGroup,
                              otherGroup].filter { !$0.categories.isEmpty })
    }
}
