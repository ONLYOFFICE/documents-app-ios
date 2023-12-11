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
    @Published var selectedOption: LinkLifeTimeOption = .sevenDays //TODO: -
}
