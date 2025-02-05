//
//  ProviderEditIndexDelegate.swift
//  Documents
//
//  Created by Pavel Chernyshev on 12.01.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

protocol ProviderEditIndexDelegate {
    func changeOrderIndex(for entity: ASCEntity, toIndex index: Int)
    func cancleEditOrderIndex()
    func applyEditedOrderIndex(completion: @escaping (ErrorMessage?) -> Void)
}
