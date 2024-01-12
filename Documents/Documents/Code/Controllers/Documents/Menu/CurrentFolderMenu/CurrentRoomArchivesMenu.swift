//
//  CurrentRoomArchivesMenu.swift
//  Documents
//
//  Created by Alexander Yuzhin on 18.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

final class CurrentRoomArchivesMenu: CurrentFolderMenuProtocol {
    private lazy var sortTypes: [ASCDocumentSortType] = [.az, .type, .tag, .author, .dateandtime]

    func contextMenu(for folder: ASCFolder, in viewController: ASCDocumentsViewController) -> UIMenu {
        guard let provider = viewController.provider else { return UIMenu() }
        let actions = provider.actions(for: folder)

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

        var entityActionsGroup: [UIMenuElement] = []

        // Copy general link
        if actions.contains(.link) {
            entityActionsGroup.append(
                UIAction(
                    title: NSLocalizedString("Copy general link", comment: "Button title"),
                    image: UIImage(systemName: "link")
                ) { action in
                    viewController.copyGeneralLinkToClipboard(room: folder)
                }
            )
        }

        // Info
        if actions.contains(.info) {
            entityActionsGroup.append(
                UIAction(
                    title: NSLocalizedString("Info", comment: "Button title"),
                    image: UIImage(systemName: "info.circle")
                ) { action in
                    viewController.navigator.navigate(to: .shareSettings(entity: folder))
                }
            )
        }

        var entityOperationsGroup: [UIMenuElement] = []

        if actions.contains(.unarchive) {
            entityOperationsGroup.append(
                UIAction(
                    title: NSLocalizedString("Restore", comment: "Button title"),
                    image: UIImage(systemName: "arrow.uturn.left.circle")
                ) { action in
                    viewController.unarchive(cell: nil, folder: folder)
                }
            )
        }

        if !folder.isRoot {
            entityOperationsGroup.append(
                UIAction(
                    title: NSLocalizedString("Delete", comment: "Button title"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { action in
                    viewController.deleteFolderAction(folder: folder)
                }
            )

            sortTypes = [.az, .size, .dateandtime]
        }

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
        let entityActionsMenu = UIMenu(title: "", options: .displayInline, children: entityActionsGroup)
        let entityOperationsMenu = UIMenu(title: "", options: .displayInline, children: entityOperationsGroup)
        let sortMenu = UIMenu(title: "", options: .displayInline, children: sortActions)
        var menus: [UIMenuElement] = [selectMenu, entityActionsMenu, entityOperationsMenu, sortMenu]

        menus.insert(selectMenu, at: 0)

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
