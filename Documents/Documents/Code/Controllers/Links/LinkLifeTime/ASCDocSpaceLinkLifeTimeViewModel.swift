//
//  ASCDocSpaceLinkLifeTimeViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 27.03.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

enum LinkLifeTimeOption: String, CaseIterable {
    case twelveHours
    case oneDay
    case sevenDays
    case unlimited
    case custom

    var localized: String {
        switch self {
        case .twelveHours:
            NSLocalizedString("12 hours", comment: "")
        case .oneDay:
            NSLocalizedString("1 day", comment: "")
        case .sevenDays:
            NSLocalizedString("7 days", comment: "")
        case .unlimited:
            NSLocalizedString("Unlimited", comment: "")
        case .custom:
            NSLocalizedString("Custom", comment: "")
        }
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

