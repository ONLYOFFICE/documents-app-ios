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

struct LinkLifeTimeModel: Identifiable {
    var id: String { option.rawValue }
    var option: LinkLifeTimeOption
    var selected: Bool
}

final class ASCDocSpaceLinkLifeTimeViewModel: ObservableObject {
    @Published var linkLifeTimeModels: [LinkLifeTimeModel] = []

    init() {
        linkLifeTimeModels = LinkLifeTimeOption.allCases.map {
            // TODO: Check default selected
            LinkLifeTimeModel(option: $0, selected: false)
        }
    }

    func select(linkLifeTimeModel: LinkLifeTimeModel) {
        linkLifeTimeModels.enumerated().forEach { index, item in
            linkLifeTimeModels[index].selected = linkLifeTimeModel.id == item.id
        }
    }
}
