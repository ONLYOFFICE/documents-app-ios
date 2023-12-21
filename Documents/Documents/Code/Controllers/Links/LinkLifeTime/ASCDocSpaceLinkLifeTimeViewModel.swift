//
//  ASCDocSpaceLinkLifeTimeViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 29.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

enum LinkLifeTimeOption: String, CaseIterable {
    case twelveHours = "12 hours"
    case oneDay = "1 day"
    case sevenDays = "7 days"
    case unlimited = "Unlimited"
    case custom = "Custom"

    var localized: String {
        NSLocalizedString(rawValue, comment: "")
    }
}

final class LinkLifeTimeViewModel: ObservableObject {
    @Published var cellModels: [SelectableLabledCellModel] = []
    private var selectedOption: LinkLifeTimeOption = .sevenDays

    init() {
        updateCellModels()
    }

    private func updateCellModels() {
        cellModels = LinkLifeTimeOption.allCases.map { option in
            SelectableLabledCellModel(
                title: option.localized,
                isSelected: selectedOption == option,
                onTapAction: { [weak self] in
                    self?.selectOption(option)
                }
            )
        }
    }

    private func selectOption(_ option: LinkLifeTimeOption) {
        selectedOption = option
        updateCellModels()
    }
}
