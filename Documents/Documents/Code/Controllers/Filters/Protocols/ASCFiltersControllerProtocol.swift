//
//  ASCFiltersControllerProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 08.06.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCFiltersControllerProtocol {
    var folder: ASCFolder? { get set }
    var provider: ASCFileProviderProtocol? { get set }
    var filtersViewController: ASCFiltersViewController { get }
    var filtersParams: [String: Any]? { get }
    var onAction: () -> Void { get set }

    init(builder: ASCFiltersCollectionViewModelBuilder, filtersViewController: ASCFiltersViewController, itemsCount: Int)
    func prepareForDisplay(total: Int)
}
