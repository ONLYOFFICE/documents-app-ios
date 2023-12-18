//
//  CurrentLocalFolderMenu.swift
//  Documents
//
//  Created by Alexander Yuzhin on 18.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

final class CurrentLocalFolderMenu: CurrentFolderMenuProtocol {
    private lazy var defaultsSortTypes: [ASCDocumentSortType] = [.dateandtime, .az, .type, .size]

    func contextMenu(for folder: ASCFolder, in viewController: ASCDocumentsViewController) -> UIMenu {
        var selectActions: [UIMenuElement] = []
        var sortActions: [UIMenuElement] = []

        selectActions.append(
            UIAction(
                title: NSLocalizedString("Select", comment: "Button title"),
                image: UIImage(systemName: "checkmark.circle")
            ) { action in
                viewController.setEditMode(!viewController.tableView.isEditing)
            }
        )

        var sortType: ASCDocumentSortType = .dateandtime
        var sortAscending = false

        if let sortInfo = UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sortDocuments) as? [String: Any] {
            if let sortBy = sortInfo["type"] as? String, !sortBy.isEmpty {
                sortType = ASCDocumentSortType(sortBy)
            }

            if let sortOrder = sortInfo["order"] as? String, !sortOrder.isEmpty {
                sortAscending = sortOrder == "ascending"
            }
        }

        let sortStates: [ASCDocumentSortStateType] = defaultsSortTypes.map { ($0, $0 == sortType) }

        for sort in sortStates {
            sortActions.append(
                UIAction(
                    title: sort.type.description,
                    image: sort.active ? (sortAscending ? UIImage(systemName: "chevron.up") : UIImage(systemName: "chevron.down")) : nil,
                    state: sort.active ? .on : .off
                ) { action in
                    var sortInfo = [
                        "type": sortType.rawValue,
                        "order": sortAscending ? "ascending" : "descending",
                    ]

                    if sortType != sort.type {
                        sortInfo["type"] = sort.type.rawValue
                    } else {
                        sortAscending = !sortAscending
                        sortInfo["order"] = sortAscending ? "ascending" : "descending"
                    }

                    UserDefaults.standard.set(sortInfo, forKey: ASCConstants.SettingsKeys.sortDocuments)
                }
            )
        }

        let selectMenu = UIMenu(title: "", options: .displayInline, children: selectActions)
        let sortMenu = UIMenu(title: "", options: .displayInline, children: sortActions)
        var menus: [UIMenuElement] = [sortMenu]

        menus.insert(selectMenu, at: 0)

        return UIMenu(title: "", options: [.displayInline], children: menus)
    }
}
