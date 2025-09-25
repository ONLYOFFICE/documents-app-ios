//
//  BrandButtonModifier.swift
//  Documents
//
//  Created by Pavel Chernyshev on 27/08/25.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct BrandButtonStyle: ButtonStyle {
    enum Kind {
        case filledCapsule
        case inline
    }

    var kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        switch kind {
        case .filledCapsule:
            configuration.label
                .modifier(WeightModifier(weight: .semibold))
                .padding(.vertical, 4)
                .padding(.horizontal, 16)
                .background(
                    (isEnabled ? Asset.Colors.brend.swiftUIColor : .secondary)
                        .opacity(
                            configuration.isPressed
                            ? 0.8
                            : isEnabled ? 1 : 0.16
                        )
                )
                .foregroundColor(.white)
                .clipShape(Capsule())

        case .inline:
            configuration.label
                .modifier(WeightModifier(weight: .regular))
                .foregroundColor(isEnabled ? Asset.Colors.brend.swiftUIColor : .secondary)
                .opacity(isEnabled ? 1 : 0.6)
        }
    }

    @Environment(\.isEnabled) private var isEnabled
}

private struct WeightModifier: ViewModifier {
    let weight: Font.Weight

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.fontWeight(weight)
        } else {
            content.font(.system(size: 16, weight: weight))
        }
    }
}

extension View {
    func brandButton(_ kind: BrandButtonStyle.Kind) -> some View {
        self.buttonStyle(BrandButtonStyle(kind: kind))
    }
}
