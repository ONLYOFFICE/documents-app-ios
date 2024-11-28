//
//  ToggleButtonView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 28.11.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ToggleButtonView: View {
    let model: ViewModel

    var body: some View {
        return Button(action: {
            model.tapHandler(model.id)
        }, label: {
            Text(model.title)
                .font(.subheadline)
                .foregroundColor(model.isActive ? Color.white : .black)
                .padding(.horizontal, .horizontalPadding)
                .padding(.vertical, 6)
        })
        .background(model.isActive ? Asset.Colors.brend.swiftUIColor : .white)
        .cornerRadius(16)
        .buttonStyle(PlainButtonStyle())
    }

    static func calculateWidth(for title: String, font: UIFont = UIFont.preferredFont(forTextStyle: .subheadline)) -> CGFloat {
        let adjustedFont = UIFontMetrics.default.scaledFont(for: font)
        let textWidth = (title as NSString).size(withAttributes: [.font: adjustedFont]).width
        return textWidth + 2 * .horizontalPadding
    }
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
