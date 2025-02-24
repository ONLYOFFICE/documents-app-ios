//
//  ASCEntityViewLayoutTypeProvider.swift
//  Documents
//
//  Created by Pavel Chernyshev on 18.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCEntityViewLayoutTypeProvider {
    var itemsViewType: ASCEntityViewLayoutType { get set }

    func itemsViewType(for folder: ASCFolder?) -> ASCEntityViewLayoutType
}

extension ASCEntityViewLayoutTypeProvider {
    var itemsViewType: ASCEntityViewLayoutType {
        get { ASCEntityViewLayoutTypeService.shared.itemsViewType }
        set { ASCEntityViewLayoutTypeService.shared.itemsViewType = newValue }
    }

    func itemsViewType(for folder: ASCFolder?) -> ASCEntityViewLayoutType {
        itemsViewType
    }
}

class ASCEntityViewLayoutTypeService {
    static let shared = ASCEntityViewLayoutTypeService()

    private let queue = DispatchQueue(
        label: "com.example.ASCEntityViewLayoutTypeService",
        qos: .userInteractive,
        attributes: .concurrent
    )

    private var type: ASCEntityViewLayoutType = ASCAppSettings.gridLayoutFiles ? .grid : .list

    private init() {}

    var itemsViewType: ASCEntityViewLayoutType {
        get {
            return queue.sync {
                ASCAppSettings.gridLayoutFiles ? .grid : .list
            }
        }
        set {
            queue.async(flags: .barrier) {
                ASCAppSettings.gridLayoutFiles = newValue == .grid
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: ASCConstants.Notifications.updateDocumentsViewLayoutType,
                        object: newValue
                    )
                }
            }
        }
    }
}
