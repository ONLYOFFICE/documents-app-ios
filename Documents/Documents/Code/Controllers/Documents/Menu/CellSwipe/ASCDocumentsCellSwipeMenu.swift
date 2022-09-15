//
//  ASCDocumentsCellSwipeMenu.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation
import MGSwipeTableCell

protocol ASCDocumentsCellSwipeMenu {
    func buildCellMenu(cell: MGSwipeTableCell) -> [MGSwipeButton]?
}
