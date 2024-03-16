//
//  ASCDocumentsViewController+OnlyOfficeActions.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 15.03.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import MBProgressHUD
import UIKit

extension ASCDocumentsViewController {
    func download(cell: UITableViewCell) {
        if cell is ASCFileCell {
            downloadFile(cell: cell)
        } else if cell is ASCFolderCell {
            let folderCell = cell as! ASCFolderCell
            downloadFolder(cell: cell, folder: folderCell.folder!)
        }
    }

    func downloadFile(cell: UITableViewCell) {
        guard
            let fileCell = cell as? ASCFileCell,
            let file = fileCell.file,
            let provider = provider
        else {
            UIAlertController.showError(
                in: self,
                message: NSLocalizedString("Could not download file.", comment: "")
            )
            return
        }

        var forceCancel = false
        let openingAlert = ASCProgressAlert(
            title: NSLocalizedString("Downloading", comment: "Caption of the processing") + "...",
            message: nil,
            handler: { cancel in
                forceCancel = cancel
            }
        )

        ASCEntityManager.shared.download(for: provider, entity: file) { [unowned self] status, progress, result, error, cancel in
            if status == .begin {
                openingAlert.show()
            }

            openingAlert.progress = progress

            if forceCancel {
                cancel = forceCancel
                provider.cancel()
                return
            }

            if status == .end || status == .error {
                if status == .error {
                    openingAlert.hide()
                    UIAlertController.showError(
                        in: self,
                        message: error?.localizedDescription ?? NSLocalizedString("Could not download file.", comment: "")
                    )
                } else {
                    if let newFile = result as? ASCFile, let rootVC = ASCViewControllerManager.shared.rootController {
                        // Switch category to 'On Device'
                        rootVC.display(provider: ASCFileManager.localProvider, folder: nil)

                        // Delay so that the loading indication is completed
                        delay(seconds: 0.6) {
                            openingAlert.hide()

                            let splitVC = ASCViewControllerManager.shared.topViewController as? ASCBaseSplitViewController
                            let documentsNC = splitVC?.detailViewController as? ASCDocumentsNavigationController
                            let documentsVC: ASCDocumentsViewController? = documentsNC?.viewControllers.first as? ASCDocumentsViewController ?? ASCViewControllerManager.shared.topViewController as? ASCDocumentsViewController

                            if let documentsVC = documentsVC {
                                documentsVC.loadFirstPage { success in
                                    if success {
                                        if let index = documentsVC.tableData.firstIndex(where: { ($0 as? ASCFile)?.title == newFile.title }) {
                                            // Scroll to new cell
                                            let indexPath = IndexPath(row: index, section: 0)
                                            documentsVC.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)

                                            // Highlight new cell
                                            delay(seconds: 0.3) {
                                                documentsVC.highlight(entity: newFile)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func favorite(cell: UITableViewCell, favorite: Bool) {
        guard
            let provider = provider,
            let fileCell = cell as? ASCFileCell,
            let file = fileCell.file
        else { return }

        var hud: MBProgressHUD?

        ASCEntityManager.shared.favorite(for: provider, entity: file, favorite: favorite) { [unowned self] status, entity, error in
            if status == .begin {
                hud = MBProgressHUD.showTopMost()
                hud?.mode = .indeterminate
            } else if status == .error {
                hud?.hide(animated: true)

                if let error {
                    UIAlertController.showError(in: self, message: error.localizedDescription)
                }
            } else if status == .end {
                if entity != nil {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: .standardDelay)

                    if let indexPath = self.tableView.indexPath(for: cell), let file = entity as? ASCFile {
                        updateProviderStatus(for: file, indexPath: indexPath)
                    }
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }

    func pinToggle(cell: UITableViewCell) {
        guard let folderCell = cell as? ASCFolderCell,
              let folder = folderCell.folder,
              let provider = provider else { return }
        let hud = MBProgressHUD.showTopMost()
        hud?.isHidden = false
        let action: ASCEntityActions = folder.pinned ? .unpin : .pin
        let processLabel: String = folder.pinned
            ? NSLocalizedString("Unpinning", comment: "Caption of the processing")
            : NSLocalizedString("Pinning", comment: "Caption of the processing")
        provider.handle(action: action, folder: folder) { [weak self] status, entity, error in
            guard let self = self else {
                hud?.hide(animated: false)
                return
            }
            self.baseProcessHandler(hud: hud, processingMessage: processLabel, status, entity, error) {
                if entity != nil {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: .standardDelay)
                    self.loadFirstPage()
                } else {
                    hud?.hide(animated: false)
                }
            }
        }
    }

    func downloadFolder(cell: UITableViewCell?, folder: ASCFolder) {
        guard let provider = provider as? ASCOnlyofficeProvider
        else { return }

        let transferAlert = ASCProgressAlert(
            title: NSLocalizedString("Downloading", comment: "Caption of the processing"),
            message: nil,
            handler: { cancel in
                if cancel {
                    provider.apiClient.request(OnlyofficeAPI.Endpoints.Operations.terminate)
                    provider.cancel()
                    log.warning("Active operations canceled")
                }
            }
        )

        transferAlert.show()

        provider.download(items: [folder]) { progress in
            transferAlert.progress = progress
        } completion: { [weak self] result in
            switch result {
            case let .success(url):
                transferAlert.hide {
                    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

                    if UIDevice.pad {
                        if let cell = cell {
                            activityViewController.popoverPresentationController?.sourceView = cell
                            activityViewController.popoverPresentationController?.sourceRect = cell.bounds
                        } else {
                            activityViewController.popoverPresentationController?.sourceView = self?.sortSelectBarButton?.customView
                            activityViewController.popoverPresentationController?.sourceRect = (self?.sortSelectBarButton?.customView!.bounds)!
                        }
                    }

                    self?.present(activityViewController, animated: true, completion: nil)
                }
            case let .failure(error):
                transferAlert.hide()
                log.error(error)

                if let self {
                    UIAlertController.showError(
                        in: self,
                        message: NSLocalizedString("Couldn't download the room.", comment: "")
                    )
                }
            }
        }
    }

    func leaveRoom(cell: UITableViewCell?, folder: ASCFolder) {
        guard let provider = provider as? ASCOnlyofficeProvider
        else { return }

        var hud: MBProgressHUD?

        let isOwner: Bool = provider.checkRoomOwner(folder: folder)
        let alertController = UIAlertController(title: NSLocalizedString("Leave the room", comment: ""), message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel, handler: nil)

        if isOwner {
            let assignOwnerAction = UIAlertAction(title: NSLocalizedString("Assign Owner", comment: ""), style: .default) { _ in
                self.navigator.navigate(to: .leaveRoom(entity: folder) { status, result, error in
                    if status == .begin {
                        hud = MBProgressHUD.showTopMost()
                    } else if status == .error {
                        hud?.hide(animated: true)
                        UIAlertController.showError(
                            in: self,
                            message: NSLocalizedString("Couldn't leave the room", comment: "")
                        )
                    } else if status == .end {
                        hud?.setSuccessState()
                        hud?.label.numberOfLines = 0
                        hud?.label.text = NSLocalizedString("You have left the room and appointed a new owner", comment: "")
                        if let cell = cell {
                            if let indexPath = self.tableView.indexPath(for: cell) {
                                self.provider?.remove(at: indexPath.row)
                                self.tableView.beginUpdates()
                                self.tableView.deleteRows(at: [indexPath], with: .fade)
                                self.tableView.endUpdates()
                                self.updateFolder(viewController: self)
                            }
                        } else {
                            if let previousViewController = self.navigationController?.previousViewController,
                               let folderItem = previousViewController.tableView.visibleCells.compactMap({ $0 as? ASCFolderCell }).first(where: { $0.folder?.id == folder.id }),
                               let indexPath = previousViewController.tableView.indexPath(for: folderItem)
                            {
                                previousViewController.provider?.remove(at: indexPath.row)
                                previousViewController.tableView.beginUpdates()
                                previousViewController.tableView.deleteRows(at: [indexPath], with: .fade)
                                previousViewController.tableView.endUpdates()

                                self.updateFolder(viewController: previousViewController)

                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                        hud?.hide(animated: false, afterDelay: .standardDelay)
                    }
                })
            }
            alertController.message = NSLocalizedString("You are the owner of this room. Before you leave the room, you must transfer the owner’s role to another user.", comment: "")

            alertController.addAction(assignOwnerAction)

        } else {
            let submitAction = UIAlertAction(title: ASCLocalization.Common.ok, style: .default) { _ in
                provider.leaveRoom(folder: folder) { status, result, error in
                    if status == .begin {
                        hud = MBProgressHUD.showTopMost()
                    } else if status == .error {
                        hud?.hide(animated: true)
                        UIAlertController.showError(
                            in: self,
                            message: NSLocalizedString("Couldn't leave the room", comment: "")
                        )
                    } else if status == .end {
                        hud?.setSuccessState()
                        hud?.label.text = NSLocalizedString("You have left the room", comment: "")
                        if let cell = cell {
                            if let indexPath = self.tableView.indexPath(for: cell) {
                                self.provider?.remove(at: indexPath.row)
                                self.tableView.beginUpdates()
                                self.tableView.deleteRows(at: [indexPath], with: .fade)
                                self.tableView.endUpdates()
                                self.updateFolder(viewController: self)
                            }
                        } else {
                            self.navigationController?.popViewController(animated: true)
                            self.updateFolder(viewController: self)
                        }
                        hud?.hide(animated: false, afterDelay: .standardDelay)
                    }
                }
            }

            alertController.message = NSLocalizedString("Do you really want to leave this room? You will be able to join it again via new invitation by a room admin.", comment: "")

            alertController.addAction(submitAction)
        }

        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    func editRoom(folder: ASCFolder) {
        let vc = EditRoomViewController(folder: folder) { _ in
            if let refreshControl = self.refreshControl {
                self.refresh(refreshControl)
                if let viewControllers = self.navigationController?.viewControllers,
                   let index = viewControllers.firstIndex(of: self),
                   index > 0
                {
                    let previousController = viewControllers[index - 1] as? ASCDocumentsViewController
                    previousController?.refresh(refreshControl)
                }
            }
        }

        vc.modalPresentationStyle = .formSheet
        vc.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize

        present(vc, animated: true, completion: nil)
    }

    func copyGeneralLinkToClipboard(room: ASCFolder) {
        if let onlyofficeProvider = provider as? ASCOnlyofficeProvider {
            let hud = MBProgressHUD.showTopMost()
            Task {
                let generalLinkResult = await onlyofficeProvider.generalLink(for: room)

                await MainActor.run {
                    switch generalLinkResult {
                    case let .success(link):
                        UIPasteboard.general.string = link
                        hud?.setState(result: .success(NSLocalizedString("Link successfully\ncopied to clipboard", comment: "Button title")))

                    case .failure:
                        hud?.setState(result: .failure(nil))
                    }

                    hud?.hide(animated: true, afterDelay: .standardDelay)
                }
            }
        }
    }

    func archive(cell: UITableViewCell?, folder: ASCFolder) {
        let processLabel: String = NSLocalizedString("Archiving", comment: "Caption of the processing")
        if let cell = cell {
            handleAction(folder: folder, action: .archive, processingLabel: processLabel, copmletionBehavior: .delete(cell))
        } else {
            handleAction(folder: folder, action: .archive, processingLabel: processLabel, copmletionBehavior: .archiveAction)
        }
    }

    func unarchive(cell: UITableViewCell?, folder: ASCFolder) {
        let processLabel: String = NSLocalizedString("Moving from archive", comment: "Caption of the processing")
        if let cell = cell {
            handleAction(folder: folder, action: .unarchive, processingLabel: processLabel, copmletionBehavior: .delete(cell))
        } else {
            handleAction(folder: folder, action: .unarchive, processingLabel: processLabel, copmletionBehavior: .archiveAction)
        }
    }

    func deleteArchive(folder: ASCFolder) {
        let alertController = UIAlertController(title: NSLocalizedString("Delete forever?", comment: ""), message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel, handler: nil)

        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { _ in
            self.removerActionController.delete(indexes: [folder.uid])
        }
        alertController.message = NSLocalizedString("You are about to delete this room. You won’t be able to restore them.", comment: "")

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    func transformToRoom(entities: [ASCEntity]) {
        let entitiesIsOnlyOneFolder: Bool = {
            guard entities.count == 1 else { return false }
            return entities[0] is ASCFolder
        }()
        let suggestedName: String = {
            guard entitiesIsOnlyOneFolder else { return "" }
            return (entities[0] as? ASCFolder)?.title ?? ""
        }()
        let vc = CreateRoomRouteViewViewController(
            roomName: suggestedName,
            hideActivityOnSuccess: false
        ) { [weak self] room in
            let hud: MBProgressHUD? = MBProgressHUD.currentHUD
            self?.provider?.transfer(
                items: entities,
                to: room,
                move: false,
                conflictResolveType: .duplicate,
                contentOnly: entitiesIsOnlyOneFolder
            ) { [weak self] status, progress, result, error, cancel in
                guard let self else { return }
                if status == .error {
                    hud?.hide(animated: false)
                    UIAlertController.showError(
                        in: self,
                        message: error?.localizedDescription ?? NSLocalizedString("Could not copy.", comment: "")
                    )
                } else if status == .end {
                    hud?.setSuccessState()
                    hud?.hide(animated: false, afterDelay: .standardDelay)
                    if let rootVC = ASCViewControllerManager.shared.rootController {
                        rootVC.display(provider: provider, folder: room, inCategory: .onlyofficeRoomShared)
                    }
                }
            }
        }

        if UIDevice.pad {
            vc.isModalInPresentation = true
            vc.modalPresentationStyle = .formSheet
        }
        present(vc, animated: true, completion: nil)
    }

    @objc func onTransformToRoomSelected(_ sender: Any) {
        let entities: [ASCEntity] = selectedIds.compactMap { uid in
            tableData.first(where: { $0.uid == uid })
        }
        guard !entities.isEmpty else { return }

        transformToRoom(entities: entities)
    }

    @objc func onRoomRestore(_ sender: Any) {
        guard selectedIds.count > 0 else { return }
        tableData.filter { selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFolder }
            .forEach {
                guard let indexPath = indexPath(by: $0), let cell = tableView.cellForRow(at: indexPath) else { return }
                unarchive(cell: cell, folder: $0)
            }
        showEmptyView(total < 1)
        updateNavBar()
        setEditMode(false)
    }

    @objc func onInfoSelected(_ sender: Any) {
        guard let provider = provider, let folder = folder, selectedIds.count == 1 else { return }
        presentShareController(provider: provider, entity: folder)
    }

    @objc func onPinSelected(_ sender: Any) {
        guard let provider = provider, selectedIds.count > 0 else { return }

        let dispatchGroup = DispatchGroup()
        var indexPathes: [IndexPath] = []
        let hud = MBProgressHUD.showTopMost()
        let isSelectedItemsPinned = isSelectedItemsPinned()
        let action: ASCEntityActions = isSelectedItemsPinned ? .unpin : .pin
        hud?.label.text = isSelectedItemsPinned
            ? NSLocalizedString("Unpinning", comment: "Caption of the processing")
            : NSLocalizedString("Pinning", comment: "Caption of the processing")
        tableData.filter { selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFolder }
            .forEach {
                guard let indexPath = indexPath(by: $0) else { return }
                dispatchGroup.enter()
                provider.handle(action: action, folder: $0) { status, _, _ in
                    if status == .end {
                        indexPathes.append(indexPath)
                    }
                    if status == .end || status == .error {
                        dispatchGroup.leave()
                    }
                }
            }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.updateNavBar()
            self.setEditMode(false)
            hud?.hide(animated: true, afterDelay: .oneSecondDelay)
            self.loadFirstPage()
        }
    }

    private func processArchive(action: ASCEntityActions, caption: String) {
        tableData.filter { self.selectedIds.contains($0.uid) }
            .compactMap { $0 as? ASCFolder }
            .forEach {
                handleAction(folder: $0, action: action, processingLabel: caption, copmletionBehavior: .archiveRestoreAction)
            }
    }

    @objc func onArchiveSelected(_ sender: Any) {
        processArchive(action: .archive, caption: NSLocalizedString("Archiving", comment: "Caption of the processing"))
    }

    @objc func onUnarchiveSelected(_ sender: Any) {
        let alertController = UIAlertController(title: NSLocalizedString("Restore rooms?", comment: ""), message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        let action = UIAlertAction(title: "Restore", style: .default) { _ in
            self.processArchive(action: .unarchive, caption: NSLocalizedString("Unarchiving", comment: "Caption of the processing"))
        }

        alertController.message = NSLocalizedString("All shared links in rooms will become active, and its contents will be available to everyone with the link. Do you want to restore the room?", comment: "")
        alertController.addAction(action)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    @objc func onRemoveSelectedArchivedRooms(_ sender: Any) {
        onTrash(ids: selectedIds, sender, notificationType: .alert)
    }
}
