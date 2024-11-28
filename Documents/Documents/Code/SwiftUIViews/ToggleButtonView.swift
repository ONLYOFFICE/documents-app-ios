//
//  ToggleButtonView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 28.11.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ToggleButtonView: View {
}

// MARK: - View Model

extension ToggleButtonView {
    struct ViewModel: Identifiable, Hashable {
        let id: String
        let title: String
        var isActive: Bool
        let tapHandler: (String) -> Void

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(title)
            hasher.combine(isActive)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
                && lhs.title == rhs.title
                && lhs.isActive == rhs.isActive
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let horizontalPadding: CGFloat = 12
}
