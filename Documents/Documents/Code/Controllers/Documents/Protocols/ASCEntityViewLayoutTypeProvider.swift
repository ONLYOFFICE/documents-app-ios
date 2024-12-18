//
//  ASCEntityViewLayoutTypeProvider.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 18.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCEntityViewLayoutTypeProvider {
    var itemsViewType: ASCEntityViewLayoutType { get set }
}

private let queue = DispatchQueue(label: "ASCEntityViewLayoutTypeProvider", attributes: .concurrent)

extension ASCEntityViewLayoutTypeProvider {
    var itemsViewType: ASCEntityViewLayoutType {
        get {
            var result: ASCEntityViewLayoutType = .list
            queue.sync {
                result = ASCAppSettings.gridLayoutFiles ? .grid : .list
            }
            return result
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
