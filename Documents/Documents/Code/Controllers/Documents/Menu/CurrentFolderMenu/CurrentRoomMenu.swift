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
        guard let provider = viewController.provider else { return UIMenu() }
        let actions = provider.actions(for: folder)

        var entityActionsGroup: [UIMenuElement] = []

        // Select
        if actions.contains(.select) {
            entityActionsGroup.append(
                UIAction(title: NSLocalizedString("Select", comment: ""), image: UIImage(systemName: "checkmark.circle"), handler: { _ in
                    viewController.onSelectAction()
                })
            )
        }

        // Edit room
        if actions.contains(.edit) {
            entityActionsGroup.append(
                UIAction(
                    title: NSLocalizedString("Edit room", comment: "Button title"),
                    image: UIImage(systemName: "gear")
                ) { action in
                    viewController.editRoom(folder: folder)
                }
            )
        }

        // Invite users
        if actions.contains(.addUsers) {
            entityActionsGroup.append(
                UIAction(
                    title: NSLocalizedString("Invite users", comment: "Button title"),
                    image: UIImage(systemName: "person.badge.plus")
                ) { action in
                    viewController.navigator.navigate(to: .addUsers(entity: folder))
                }
            )
        }

        // Copy general link
        if actions.contains(.link) {
            entityActionsGroup.append(
                UIAction(
                    title: folder.roomType == .colobaration
                        ? NSLocalizedString("Copy link", comment: "Button title")
                        : NSLocalizedString("Copy general link", comment: "Button title"),
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

        if actions.contains(.disableNotifications) {
            entityActionsGroup.append(
                UIAction(
                    title: folder.mute
                        ? NSLocalizedString("Disable notifications", comment: "")
                        : NSLocalizedString("Enable notifications", comment: ""),
                    image: folder.mute
                        ? UIImage(systemName: "bell.slash")
                        : UIImage(systemName: "bell")
                ) { _ in
                    viewController.disableNotifications(room: folder)
                }
            )
        }

        var entityOperationsGroup: [UIMenuElement] = []

        // Download
        if actions.contains(.download) {
            entityOperationsGroup.append(
                UIAction(
                    title: NSLocalizedString("Download", comment: "Button title"),
                    image: UIImage(systemName: "square.and.arrow.down")
                ) { action in
                    viewController.downloadFolder(cell: nil, folder: folder)
                }
            )
        }

        // Move to archive
        if actions.contains(.archive) {
            entityOperationsGroup.append(
                UIAction(
                    title: NSLocalizedString("Move to archive", comment: "Button title"),
                    image: UIImage(systemName: "archivebox")
                ) { action in
                    viewController.archive(cell: nil, folder: folder)
                }
            )
        }

        if actions.contains(.leave) {
            // Leave the room
            entityOperationsGroup.append(
                UIAction(
                    title: NSLocalizedString("Leave the room", comment: "Button title"),
                    image: UIImage(systemName: "arrow.right.square")
                ) { action in
                    viewController.leaveRoom(cell: nil, folder: folder)
                }
            )
        }

        // Sort
        var sortGroup: [UIMenuElement] = []

        if !folder.isRoot {
            sortTypes = [.az, .size, .dateandtime]
        }

        let (sortType, sortAscending) = sortDetails(sortInfo: sortInfo(forRootFolderType: folder))
        let sortStates: [ASCDocumentSortStateType] = sortTypes.map { ($0, $0 == sortType) }
        if !folder.isEmpty {
            for sort in sortStates {
                sortGroup.append(
                    Self.buildUIAction(
                        sortState: sort,
                        sortType: sortType,
                        sortAscending: sortAscending,
                        folder: folder
                    )
                )
            }
        }

        let entityActionsMenu = UIMenu(title: "", options: .displayInline, children: entityActionsGroup)
        let entityOperationsMenu = UIMenu(title: "", options: .displayInline, children: entityOperationsGroup)
        let sortMenu = UIMenu(title: "", options: .displayInline, children: sortGroup)

        let menus: [UIMenuElement] = [
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
