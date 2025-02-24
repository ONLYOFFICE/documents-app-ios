//
//  ASCDocumentsViewController+DragDrop.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.03.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

private struct ItemDragInfo {
    struct LastDropPosition {
        let folder: ASCFolder
        let time = Date()
    }

    var srcFolder: ASCFolder?
    var srcController: ASCDocumentsViewController?
    var lastDropPosition: LastDropPosition?
}

// MARK: - UICollectionViewDragDelegate

extension ASCDocumentsViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard
            collectionView.cellForItem(at: indexPath) != nil,
            let providerId = provider?.id,
            provider?.allowDragAndDrop(for: tableData[indexPath.row]) == true
        else { return [] }

        let documentItemProvider = ASCEntityItemProvider(providerId: providerId, entity: tableData[indexPath.row])
        let itemProvider = NSItemProvider(object: documentItemProvider)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: any UIDragSession) {
        guard let folder, !isEditingIndexMode else { return }

        session.localContext = ItemDragInfo(
            srcFolder: folder,
            srcController: self,
            lastDropPosition: nil
        )
        setEditMode(false)
    }
}

// MARK: - UICollectionViewDropDelegate

extension ASCDocumentsViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: any UICollectionViewDropCoordinator) {
        var srcFolder: ASCFolder?
        var dstFolder = folder
        var srcProvider: ASCFileProviderProtocol?
        let dstProvider = provider
        var srcProviderId: String?
        var items: [ASCEntity] = []

        if let destinationIndexPath = coordinator.destinationIndexPath {
            if let folder = tableData[min(destinationIndexPath.row, tableData.count - 1)] as? ASCFolder {
                dstFolder = folder
            }
        }

        for item in coordinator.items {
            let semaphore = DispatchSemaphore(value: 0)
            item.dragItem.itemProvider.loadObject(ofClass: ASCEntityItemProvider.self, completionHandler: { entityProvider, error in
                if let entityProvider = entityProvider as? ASCEntityItemProvider {
                    srcProviderId = entityProvider.providerId

                    if let file = entityProvider.entity as? ASCFile {
                        items.append(file)
                    } else if let folder = entityProvider.entity as? ASCFolder {
                        items.append(folder)
                    }
                }
                semaphore.signal()
            })
            semaphore.wait()
        }

        if items.count < 1 {
            return
        }

        if let srcProviderId = srcProviderId {
            if srcProviderId == ASCFileManager.localProvider.id {
                srcProvider = ASCFileManager.localProvider
            } else if srcProviderId == ASCFileManager.onlyofficeProvider?.id {
                srcProvider = ASCFileManager.onlyofficeProvider
            } else {
                srcProvider = ASCFileManager.cloudProviders.first(where: { $0.id == srcProviderId })
            }
        }

        let contextInfo = coordinator.session.localDragSession?.localContext as? ItemDragInfo

        if let contextInfo = contextInfo {
            srcFolder = contextInfo.srcFolder

            // Hotfix parent of items for some providers
            for item in items {
                if let file = item as? ASCFile {
                    file.parent = srcFolder
                }
                if let folder = item as? ASCFolder {
                    folder.parent = srcFolder
                }
            }
        }

        if isEditingIndexMode, let editIndexDelegate = provider as? ProviderEditIndexDelegate {
            for item in items {
                if let destIndex = coordinator.destinationIndexPath?.item {
                    editIndexDelegate.changeOrderIndex(for: item, toIndex: destIndex)
                }
            }
            collectionView.reloadData()
        }

        if let srcProvider = srcProvider,
           let dstProvider = dstProvider,
           let srcFolder = srcFolder,
           let dstFolder = dstFolder,
           !isEditingIndexMode
        {
            let move = srcProvider.allowDelete(entity: items.first)
            let isInsideTransfer = (srcProvider.id == dstProvider.id) && !(srcProvider is ASCGoogleDriveProvider)

            if !isInsideTransfer {
                var forceCancel = false

                let transferAlert = ASCProgressAlert(
                    title: move
                        ? (isTrash(srcFolder)
                            ? NSLocalizedString("Recovery", comment: "Caption of the processing")
                            : NSLocalizedString("Moving", comment: "Caption of the processing"))
                        : NSLocalizedString("Copying", comment: "Caption of the processing"),
                    message: nil,
                    handler: { cancel in
                        forceCancel = cancel
                    }
                )

                transferAlert.show()
                transferAlert.progress = 0

                ASCEntityManager.shared.transfer(from: (items: items, provider: srcProvider),
                                                 to: (folder: dstFolder, provider: dstProvider),
                                                 move: move)
                { [weak self] progress, complate, success, newItems, error, cancel in
                    log.debug("Transfer procress: \(Int(progress * 100))%")

                    if forceCancel {
                        cancel = forceCancel
                    }

                    DispatchQueue.main.async { [weak self] in
                        if complate {
                            transferAlert.hide()

                            if success {
                                log.info("Items copied")

                                guard let strongSelf = self else { return }

                                // Append new items to destination controller
                                if let newItems = newItems, dstFolder.id == strongSelf.folder?.id {
                                    strongSelf.provider?.add(items: newItems, at: 0)
                                    strongSelf.collectionView.reloadData()

                                    for index in 0 ..< newItems.count {
                                        if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) {
                                            strongSelf.highlight(cell: cell)
                                        }
                                    }
                                }

                                // Remove items from source controller if move
                                if move,
                                   let contextInfo = contextInfo,
                                   let srcDocumentsVC = contextInfo.srcController
                                {
                                    for item in items {
                                        if let index = srcDocumentsVC.tableData.firstIndex(where: { $0.id == item.id }) {
                                            srcDocumentsVC.provider?.remove(at: index)
                                        }
                                    }
                                    srcDocumentsVC.collectionView.reloadData()
                                }
                            } else {
                                log.error("Items don't copied")
                            }

                            if let strongSelf = self,
                               srcProvider.type != .local || dstProvider.type != .local,
                               !ASCNetworkReachability.shared.isReachable
                            {
                                UIAlertController.showError(
                                    in: strongSelf,
                                    message: NSLocalizedString("Check your internet connection", comment: "")
                                )
                            }

                        } else {
                            transferAlert.progress = progress
                        }
                    }
                }
            } else {
                insideCheckTransfer(items: items, to: dstFolder, move: move, complation: { [weak self] conflictResolveType, cancel in
                    guard let self else { return }

                    if !cancel {
                        self.insideTransfer(items: items, to: dstFolder, move: move, conflictResolveType: conflictResolveType, completion: { entities in

                            // TODO: Fetch information about the moving elements and add them using the "add" function.
                            delay(seconds: 0.3) { [self] in
                                self.loadFirstPage()
                            }

                            // Remove items from source controller if move
                            if move,
                               let contextInfo = contextInfo,
                               let srcDocumentsVC = contextInfo.srcController
                            {
                                for item in items {
                                    if let index = srcDocumentsVC.tableData.firstIndex(where: { $0.id == item.id }) {
                                        srcDocumentsVC.provider?.remove(at: index)
                                    }
                                }
                                srcDocumentsVC.collectionView.reloadData()
                                srcDocumentsVC.showEmptyView(srcDocumentsVC.total < 1)
                                srcDocumentsVC.updateNavBar()
                            }
                        })
                    }
                })
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, canHandle session: any UIDropSession) -> Bool {
        if session.canLoadObjects(ofClass: ASCEntityItemProvider.self), let folder {
            if let provider, provider.allowEdit(entity: folder), !isTrash(folder) {
                return true
            }
        }
        return false
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: any UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if session.localDragSession != nil {
            guard !isEditingIndexMode else {
                return UICollectionViewDropProposal(operation: .move)
            }

            dragHighlightItem()

            if let provider, provider.allowEdit(entity: folder) {
                if let indexPath = destinationIndexPath, indexPath.row < tableData.count, tableData[indexPath.row] is ASCFolder {
                    let targetCell = collectionView.cellForItem(at: indexPath)
                    dragHighlightItem(targetCell)

                    if let localContext = session.localDragSession?.localContext as? ItemDragInfo {
                        if let targetFolder = (targetCell as? ASCFolderViewCell)?.entity as? ASCFolder {
                            if let lastDropPosition = localContext.lastDropPosition {
                                if Date().secondsSince(lastDropPosition.time) > 2 {
                                    var newDropInfo = localContext
                                    newDropInfo.lastDropPosition = nil
                                    session.localDragSession?.localContext = newDropInfo
                                    openFolder(folder: targetFolder)
                                }
                            } else {
                                var newDropInfo = localContext
                                newDropInfo.lastDropPosition = ItemDragInfo.LastDropPosition(folder: targetFolder)
                                session.localDragSession?.localContext = newDropInfo
                            }
                        } else {
                            var newDropInfo = localContext
                            newDropInfo.lastDropPosition = nil
                            session.localDragSession?.localContext = newDropInfo
                        }
                    }

                    return UICollectionViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
                }

                // Check if not source folder
                if let contextInfo = session.localDragSession?.localContext as? ItemDragInfo,
                   let srcFolder = contextInfo.srcFolder,
                   srcFolder.uid != folder?.uid
                {
                    return UICollectionViewDropProposal(operation: .copy)
                }
            }
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: any UIDropSession) {
        session.localDragSession?.localContext = nil
        dragHighlightItem()
    }

    private func dragHighlightItem(_ cell: UICollectionViewCell? = nil) {
        for cell in collectionView.visibleCells {
            cell.backgroundColor = .systemBackground
        }

        if let cell {
            cell.backgroundColor = .tertiarySystemGroupedBackground
        }
    }
}
