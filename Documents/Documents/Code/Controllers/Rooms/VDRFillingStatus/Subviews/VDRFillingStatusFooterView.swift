//
//  VDRFillingStatusFooterView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 6.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

/// Footer with Stop/Start actions
struct VDRFillingStatusFooterView: View {
    let stopEnabled: Bool
    let fillEnabled: Bool
    let onStop: () -> Void
    let onFill: () -> Void

    var body: some View {
        HStack {
            Button("Stop filling", action: onStop)
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
                .buttonStyle(.borderless)
                .disabled(!stopEnabled)
            Spacer()
            Button("Fill", action: onFill)
                .buttonStyle(FooterButtonStyle(color: fillEnabled ? .blue : .secondary))
                .disabled(!fillEnabled)
        }
        .padding()
        .background(Color(.systemBackground).ignoresSafeArea(edges: .bottom))
    }
}

struct FooterButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(16)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
