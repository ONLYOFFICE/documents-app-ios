//
//  CurrentRoomMenu.swift
//  Documents
//
//  Created by Alexander Yuzhin on 18.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

final class CurrentRoomMenu: CurrentFolderMenuProtocol {
    private lazy var sortTypes: [ASCDocumentSortType] = [.az, .type, .tag, .author, .dateandtime]

    func contextMenu(for folder: ASCFolder, in viewController: ASCDocumentsViewController) -> UIMenu {
        var selectGroup: [UIMenuElement] = []

        // Select
        selectGroup.append(
            UIAction(
                title: NSLocalizedString("Select", comment: "Button title"),
                image: UIImage(systemName: "checkmark.circle")
            ) { action in
                viewController.setEditMode(!viewController.tableView.isEditing)
            }
        )

        var entityActionsGroup: [UIMenuElement] = []

        // Edit room
        entityActionsGroup.append(
            UIAction(
                title: NSLocalizedString("Edit room", comment: "Button title"),
                image: UIImage(systemName: "gear")
            ) { action in
                print("Call Edit room")
            }
        )

        // Invite users
        entityActionsGroup.append(
            UIAction(
                title: NSLocalizedString("Invite users", comment: "Button title"),
                image: UIImage(systemName: "person.badge.plus")
            ) { action in
                print("Invite users")
            }
        )

        // Copy general link
        entityActionsGroup.append(
            UIAction(
                title: NSLocalizedString("Copy general link", comment: "Button title"),
                image: UIImage(systemName: "link")
            ) { action in
                print("Copy general link")
            }
        )

        // Info
        entityActionsGroup.append(
            UIAction(
                title: NSLocalizedString("Info", comment: "Button title"),
                image: UIImage(systemName: "info.circle")
            ) { action in
                print("Info")
            }
        )

        var entityOperationsGroup: [UIMenuElement] = []

        // Info
        entityOperationsGroup.append(
            UIAction(
                title: NSLocalizedString("Download", comment: "Button title"),
                image: UIImage(systemName: "square.and.arrow.down")
            ) { action in
                print("Download")
            }
        )

        // Move to archive
        entityOperationsGroup.append(
            UIAction(
                title: NSLocalizedString("Move to archive", comment: "Button title"),
                image: UIImage(systemName: "archivebox")
            ) { action in
                print("Move to archive")
            }
        )

        // Leave the room
        entityOperationsGroup.append(
            UIAction(
                title: NSLocalizedString("Leave the room", comment: "Button title"),
                image: UIImage(systemName: "arrow.right.square")
            ) { action in
                print("Leave the room")
            }
        )

        // Sort
        var sortGroup: [UIMenuElement] = []

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

        let sortStates: [ASCDocumentSortStateType] = sortTypes.map { ($0, $0 == sortType) }

        for sort in sortStates {
            sortGroup.append(
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

        let selectMenu = UIMenu(title: "", options: .displayInline, children: selectGroup)
        let entityActionsMenu = UIMenu(title: "", options: .displayInline, children: entityActionsGroup)
        let entityOperationsMenu = UIMenu(title: "", options: .displayInline, children: entityOperationsGroup)
        let sortMenu = UIMenu(title: "", options: .displayInline, children: sortGroup)

        var menus: [UIMenuElement] = [
            selectMenu,
            entityActionsMenu,
            entityOperationsMenu,
            sortMenu,
        ]

        return UIMenu(title: "", options: [.displayInline], children: menus)
    }

    func actionSheet(for folder: ASCFolder, sender: UIView?, in viewController: ASCDocumentsViewController) -> UIAlertController {
        let moreController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            tintColor: nil
        )

        moreController.addAction(
            UIAlertAction(
                title: NSLocalizedString("Select", comment: "Button title"),
                style: .default,
                handler: { [unowned viewController] action in
                    viewController.setEditMode(!viewController.tableView.isEditing)
                }
            )
        )

        moreController.addAction(
            UIAlertAction(
                title: NSLocalizedString("Sort", comment: "Button title"),
                style: .default,
                handler: { [unowned viewController] action in
                    if let sender {
                        viewController.onSortAction(sender)
                    }
                }
            )
        )

        moreController.addAction(
            UIAlertAction(
                title: ASCLocalization.Common.cancel,
                style: .cancel,
                handler: nil
            )
        )

        return moreController
    }
}
