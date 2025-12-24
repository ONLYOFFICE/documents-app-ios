//
//  ASCDocumentsViewController+ASCProviderDelegate.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import SwiftRater
import UIKit

extension ASCDocumentsViewController: ASCProviderDelegate {
    func openProgress(file: ASCFile, title: String, _ progress: Float) -> ASCEditorManagerOpenHandler {
        var forceCancel = false
        let openingAlert = ASCProgressAlert(title: title, message: nil, handler: { cancel in
            forceCancel = cancel
        })

        openingAlert.show()
        openingAlert.progress = progress

        let openHandler: ASCEditorManagerOpenHandler = { [weak self] status, progress, error, cancel in
            openingAlert.progress = progress

            if forceCancel {
                cancel = forceCancel
                self?.provider?.cancel()
                return
            }

            if status == .end || status == .error || status == .silentError {
                openingAlert.progress = 1
                openingAlert.hide()

                if status == .error {
                    guard let self else { return }

                    UIAlertController.showError(
                        in: self,
                        message: error?.localizedDescription ?? NSLocalizedString("Could not open file.", comment: "")
                    )
                }
            }
        }

        return openHandler
    }

    func closeProgress(file: ASCFile, title: String) -> ASCEditorManagerCloseHandler {
        var hud: MBProgressHUD?

        let originalFile = file
        let closeHandler: ASCEditorManagerCloseHandler = { [weak self] status, progress, file, error, cancel in
            log.info("Close file progress. Status: \(status), progress: \(progress), error: \(String(describing: error))")

            if status == .begin {
                if hud == nil, file?.device == true {
                    MBProgressHUD.currentHUD?.hide(animated: false)
                    hud = MBProgressHUD.showTopMost()
                    hud?.mode = .indeterminate
                    hud?.label.text = title
                }
            } else if status == .error {
                hud?.hide(animated: true)

                delay(seconds: 3.0) {
                    MBProgressHUD.currentHUD?.hide(animated: false)
                }

                guard let self else { return }

                if let error {
                    UIAlertController.showError(
                        in: self,
                        message: error.localizedDescription
                    )
                }
            } else if status == .end {
                hud?.setSuccessState()
                hud?.hide(animated: false, afterDelay: .standardDelay)

                delay(seconds: 3.0) {
                    MBProgressHUD.currentHUD?.hide(animated: false)
                }

                SwiftRater.incrementSignificantUsageCount()

                guard let self else { return }

                /// Update file info
                let updateFileInfo = {
                    let newFile = file ?? originalFile

                    if newFile.openVersionMode {
                        newFile.openVersionMode = false
                        return
                    }

                    if let index = self.tableData.firstIndex(where: { entity -> Bool in
                        guard let file = entity as? ASCFile else { return false }
                        return file.id == newFile.id || file.id == originalFile.id
                    }) {
                        self.updateProviderStatus(for: newFile)
                    } else {
                        self.provider?.add(item: newFile, at: 0)
                        UIView.performWithoutAnimation { [weak self] in
                            self?.collectionView.reloadData()
                        }
                        self.showEmptyView(self.total < 1)
                        self.updateNavBar()

                        let updateIndexPath = IndexPath(row: 0, section: 0)
                        let hasSection = self.collectionView.numberOfSections > updateIndexPath.section
                        let hasItem = hasSection && self.collectionView.numberOfItems(inSection: updateIndexPath.section) > updateIndexPath.item
                        guard hasItem else { return }

                        DispatchQueue.main.async {
                            self.collectionView.scrollToItem(at: updateIndexPath, at: .centeredVertically, animated: true)
                            if let updatedCell = self.collectionView.cellForItem(at: updateIndexPath) {
                                self.highlight(cell: updatedCell)
                            }
                        }
                    }
                }

                if self.provider?.type == .local {
                    self.loadFirstPage { success in
                        updateFileInfo()
                    }
                } else {
                    updateFileInfo()
                }
            }
        }

        return closeHandler
    }

    func updateItems(provider: ASCFileProviderProtocol) {
        UIView.performWithoutAnimation { [weak self] in
            self?.collectionView.reloadData()
        }

        // TODO: Or search diff and do it animated

        showEmptyView(total < 1)
    }

    func updateItems(at indexes: Set<Int>) {
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadItems(at: indexes.map { IndexPath(row: $0, section: 0) })
        }
    }

    func presentShareController(provider: ASCFileProviderProtocol, entity: ASCEntity) {
        if let keyWindow = UIApplication.shared.keyWindow {
            if var topController = keyWindow.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                presentShareController(in: topController, entity: entity)
            }
        }
    }
}

private extension ASCDocumentsViewController {
    /// Helper function to present share screen from editors
    /// - Parameters:
    ///   - parent: Parent view controller
    ///   - entity: Entity to share
    private func presentShareController(in parent: UIViewController, entity: ASCEntity) {
        if let folder = entity as? ASCFolder {
            folder.isRoom
                ? navigator.navigate(to: .sharingLink(entityType: .room(folder)))
                : navigator.navigate(to: .sharingLink(entityType: .folder(folder)))
        }

        if let file = entity as? ASCFile, ASCOnlyofficeProvider.isDocspaceApi {
            let shareRoomViewController = SharingInfoRootViewController(entityType: .file(file))
            let shareRoomNavigationVC = ASCBaseNavigationController(rootASCViewController: shareRoomViewController)

            shareRoomNavigationVC.modalPresentationStyle = .formSheet
            shareRoomNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
            parent.present(shareRoomNavigationVC, animated: true)
        } else {
            let sharedViewController = ASCSharingOptionsViewController(sourceViewController: self)
            let sharedNavigationVC = ASCBaseNavigationController(rootASCViewController: sharedViewController)

            sharedNavigationVC.modalPresentationStyle = .formSheet
            sharedNavigationVC.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize

            parent.present(sharedNavigationVC, animated: true, completion: nil)

            sharedViewController.setup(entity: entity)
            sharedViewController.requestToLoadRightHolders()
        }
    }
}
