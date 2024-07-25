//
//  ASCThirdpartySelectFolderProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 14.07.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

final class ASCThirdpartySelectFolderProvider: ASCFileProviderProtocol {
    var id: String?

    var type: ASCFileProviderType

    var rootFolder: ASCFolder

    var user: ASCUser?

    var items: [ASCEntity] = []

    var page: Int = 0

    var total: Int = 0

    var authorization: String?

    var delegate: (any ASCProviderDelegate)?

    var filterController: (any ASCFiltersControllerProtocol)?

    init(rootFolder: ASCFolder, type: ASCFileProviderType) {
        self.rootFolder = rootFolder
        self.type = type
    }

    func copy() -> any ASCFileProviderProtocol {
        let copy = ASCThirdpartySelectFolderProvider(
            rootFolder: rootFolder,
            type: type
        )

        copy.items = items.map { $0 }
        copy.page = page
        copy.total = total
        copy.delegate = delegate
        copy.authorization = authorization

        return copy
    }

    func reset() {
        total = 0
        items.removeAll()
    }

    func add(item: ASCEntity, at index: Int) {
        if !items.contains(where: { $0.uid == item.uid }) {
            items.insert(item, at: index)
            total += 1
        }
    }

    func add(items: [ASCEntity], at index: Int) {
        let uniqItems = items.filter { item -> Bool in
            !self.items.contains(where: { $0.uid == item.uid })
        }
        self.items.insert(contentsOf: uniqItems, at: index)
        total += uniqItems.count
    }

    func remove(at index: Int) {
        items.remove(at: index)
        total -= 1
    }

    func fetch(for folder: ASCFolder, parameters: [String: Any?], completeon: ASCProviderCompletionHandler?) {
        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Folders.path(of: folder)) { [weak self] response, error in
            guard let self else {
                return
            }

            var currentFolder = folder

            if let path = response?.result {
                self.total = path.total

                if let current = path.current {
                    currentFolder = current
                }

                if self.page == 0 {
                    self.items.removeAll()
                }

                let entities: [ASCEntity] = (path.folders + path.files).map { entitie in
                    if let folder = entitie as? ASCFolder {
                        folder.parent = currentFolder
                        return folder
                    } else if let file = entitie as? ASCFile {
                        file.parent = currentFolder
                        return file
                    }
                    return entitie
                }

                self.items += entities

                completeon?(self, currentFolder, true, nil)
            } else {
                completeon?(self, currentFolder, false, error)
            }
        }
    }

    func allowEdit(entity: AnyObject?) -> Bool {
        true
    }
}

// MARK: - Unsupported funcs

extension ASCThirdpartySelectFolderProvider {
    func open(file: ASCFile, openMode: ASCDocumentOpenMode, canEdit: Bool) {
        log.error(#function, " doesn't supported")
    }

    func preview(file: ASCFile, files: [ASCFile]?, in view: UIView?) {
        log.error(#function, " doesn't supported")
    }
}
