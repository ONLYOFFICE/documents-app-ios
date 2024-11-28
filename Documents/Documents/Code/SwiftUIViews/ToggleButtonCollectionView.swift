//
//  ToggleButtonCollectionView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 28.11.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ToggleButtonCollectionView: View {
    typealias ButtonModel = ToggleButtonView.ViewModel
    private var buttonRows: [[ButtonModel]] {
        var rows: [[ButtonModel]] = []
        var currentRow: [ButtonModel] = []
        var remainingWidth = width

        for button in buttonModels {
            let buttonWidth = ToggleButtonView.calculateWidth(for: button.title) + .spaceBetweenItems
            if buttonWidth > remainingWidth {
                rows.append(currentRow)
                currentRow = [button]
                remainingWidth = width - buttonWidth
            } else {
                currentRow.append(button)
                remainingWidth -= buttonWidth
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

// MARK: - Constants

private extension CGFloat {
    static let spaceBetweenItems: CGFloat = 16
}
