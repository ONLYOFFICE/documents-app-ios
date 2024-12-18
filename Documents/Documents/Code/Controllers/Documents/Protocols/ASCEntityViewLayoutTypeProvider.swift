//
//  ASCEntityViewLayoutTypeProvider.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 18.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

protocol ASCEntityViewLayoutTypeProvider {
    var itemsViewType: ASCEntityViewLayoutType { get set }
}

extension ASCEntityViewLayoutTypeProvider {
    
    var itemsViewType: ASCEntityViewLayoutType {
        get {
            ASCAppSettings.gridLayoutFiles ? .grid : .list
        }
        set {
            ASCAppSettings.gridLayoutFiles = newValue == .grid
            NotificationCenter.default.post(name: ASCConstants.Notifications.updateDocumentsViewLayoutType, object: newValue)
        }
    }
}
