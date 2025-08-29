//
//  BrandButtonModifier.swift
//  Documents
//
//  Created by Pavel Chernyshev on 27/08/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

enum BrandButtonKind {
    /// branded background + white text + capsule
    case filledCapsule
    /// only branded text
    case inline
}

extension Text {
    @ViewBuilder
    func brandButton(_ kind: BrandButtonKind, isEnabled: Bool = true) -> some View {
        switch kind {
        case .filledCapsule:
            fontWeight(.semibold)
                .padding(.vertical, 4)
                .padding(.horizontal, 16)
                .background(
                    isEnabled
                        ? Asset.Colors.brend.swiftUIColor
                        : Color.secondary.opacity(0.16)
                )
                .foregroundColor(.white)
                .clipShape(Capsule())
        case .inline:
            fontWeight(.regular)
                .foregroundColor(isEnabled ? Asset.Colors.brend.swiftUIColor : .secondary)
                .opacity(isEnabled ? 1 : 0.6)
        }
    }
}
