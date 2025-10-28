//
//  ASCOnlyofficeDocSpaceCategoriesGroper.swift
//  Documents
//
//  Created by Pavel Chernyshev on 9.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeDocSpaceCategoriesGroper: ASCOnlyofficeCategoriesGrouper {
    private lazy var apiClient = OnlyofficeApiClient.shared

    func group(categories: [ASCOnlyofficeCategory]) -> ASCOnlyofficeCategoriesGroup {
        guard let docspaceVersion = apiClient.serverVersion?.docSpace,
              docspaceVersion.isVersion(greaterThanOrEqualTo: "3.5.0")
        else {
            return groupDocumentsAndRoomTogether(categories: categories)
        }
        return groupDocumentsAndRoomSeparate(categories: categories)
    }

    private func groupDocumentsAndRoomTogether(categories: [ASCOnlyofficeCategory]) -> ASCOnlyofficeCategoriesGroup {
        var roomsGroup = makeTitledRoomsGroup()
        var filesGroup = makeTitledFilesGroup()
        var otherGroup = makeEmptyTitledGroup()

        for category in categories {
            switch category.folder?.rootFolderType {
            case .user:
                roomsGroup.categories.append(category)
            case .favorites, .recent, .trash:
                filesGroup.categories.append(category)
            default:
                category.isDocSpaceRoom
                    ? roomsGroup.categories.append(category)
                    : otherGroup.categories.append(category)
            }
        }
        return .titledGroups(
            [
                roomsGroup,
                filesGroup,
                otherGroup,
            ].filter { !$0.categories.isEmpty }
        )
    }

    private func groupDocumentsAndRoomSeparate(categories: [ASCOnlyofficeCategory]) -> ASCOnlyofficeCategoriesGroup {
        var roomsGroup = makeTitledRoomsGroup()
        var filesGroup = makeTitledFilesGroup()
        var otherGroup = makeEmptyTitledGroup()

        for category in categories {
            switch category.folder?.rootFolderType {
            case .user, .share, .favorites, .recent:
                filesGroup.categories.append(category)
            case .virtualRooms, .archive, .trash:
                roomsGroup.categories.append(category)
            default:
                category.isDocSpaceRoom
                    ? roomsGroup.categories.append(category)
                    : otherGroup.categories.append(category)
            }
        }
        return .titledGroups(
            [
                filesGroup,
                roomsGroup,
                otherGroup,
            ].filter { !$0.categories.isEmpty }
        )
    }

    private func makeTitledRoomsGroup() -> ASCOnlyofficeCategoriesGroup.TitledGroup {
        (
            title: NSLocalizedString("Rooms", comment: "DocSpace rooms"),
            categories: []
        )
    }

    private func makeTitledFilesGroup() -> ASCOnlyofficeCategoriesGroup.TitledGroup {
        (
            title: NSLocalizedString("Files", comment: ""),
            categories: []
        )
    }

    private func makeEmptyTitledGroup() -> ASCOnlyofficeCategoriesGroup.TitledGroup {
        (
            title: " ",
            categories: []
        )
    }
}
