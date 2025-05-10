//
//  VDRFillingStatusFooterView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 6.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

/// Footer with Stop/Start actions
struct VDRFillingStatusFooterView: View {
    let status: VDRFillingStatusApplicationStatus?
    let isLoading: Bool
    let onStop: () -> Void
    let onStart: () -> Void

    var body: some View {
        HStack {
            if status == .inProgress {
                Button("Stop filling", action: onStop)
                    .buttonStyle(FooterButtonStyle(color: .red))
            } else {
                Button("Fill", action: onStart)
                    .buttonStyle(FooterButtonStyle(color: .blue))
                    .disabled(isLoading)
            }
        }
        .padding()
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }
}
