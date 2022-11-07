//
//  ASCDocumentsEntityRemoverActionController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import MBProgressHUD

final class ASCDocumentsEntityRemoverActionController: ASCEntityRemoverActionController, FileProviderHolder, FolderHolder {
    typealias EntitiesGetter = (Set<String>) -> (localItems: [ASCEntity], cloudItems: [ASCEntity])
    typealias ProviderIndexesGetter = ([ASCEntity]) -> [IndexPath]
    typealias RemovedItemsHandler = ([IndexPath]) -> Void
    typealias ErrorHandler = (String?) -> Void

    var provider: ASCFileProviderProtocol?
    var folder: ASCFolder?
    let itemsGetter: EntitiesGetter
    let providerIndexesGetter: ProviderIndexesGetter
    let removedItemsHandler: RemovedItemsHandler
    let errorHandeler: ErrorHandler

    init(provider: ASCFileProviderProtocol? = nil,
         folder: ASCFolder?,
         itemsGetter: @escaping EntitiesGetter,
         providerIndexesGetter: @escaping ProviderIndexesGetter,
         removedItemsHandler: @escaping RemovedItemsHandler,
         errorHandeler: @escaping ErrorHandler)
    {
        self.provider = provider
        self.folder = folder
        self.itemsGetter = itemsGetter
        self.providerIndexesGetter = providerIndexesGetter
        self.removedItemsHandler = removedItemsHandler
        self.errorHandeler = errorHandeler
    }

    func delete(indexes: Set<String>) {
        let (localItems, cloudItems) = itemsGetter(indexes)

        var deteteItems: [ASCEntity] = []
        deleteGroup(items: localItems) { [unowned self] items in
            deteteItems += items ?? []

            deleteGroup(items: cloudItems) { [unowned self] items in
                deteteItems += items ?? []

                // Remove data
                if let provider = self.provider {
                    let deletedIndexes = providerIndexesGetter(deteteItems)
                    deletedIndexes.forEach {
                        provider.remove(at: $0.row)
                    }
                    removedItemsHandler(deletedIndexes)
                }
            }
        }
    }

    func deleteGroup(items: [ASCEntity], completion: (([ASCEntity]?) -> Void)? = nil) {
        guard let provider = provider,
              let folder = folder else { return }

        if items.isEmpty {
            completion?(nil)
            return
        }

        var hud: MBProgressHUD?

        ASCEntityManager.shared.delete(for: provider, entities: items, from: folder) { [errorHandeler] status, result, error in
            if status == .begin {
                if hud == nil {
                    hud = MBProgressHUD.showTopMost()
                    hud?.mode = .indeterminate
                    hud?.label.text = NSLocalizedString("Deleting", comment: "Caption of the processing")
                }
            } else if status == .error {
                hud?.hide(animated: true)
                hud = nil
                errorHandeler(error)
                completion?(nil)
            } else if status == .end {
                hud?.setSuccessState()
                hud?.hide(animated: false, afterDelay: 1.3)
                hud = nil

                let deletedItems = items.filter { provider.allowDelete(entity: $0) || (($0 as? ASCFolder)?.isThirdParty ?? false) }
                completion?(deletedItems)
            }
        }
    }
}
