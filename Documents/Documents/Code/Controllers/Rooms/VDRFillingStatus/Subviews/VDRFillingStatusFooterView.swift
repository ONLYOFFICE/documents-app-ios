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
            Button(action: onStop) {
                Text("Stop filling")
                    .brandButton(.inline, isEnabled: stopEnabled)
            }
            Spacer()
            Button(action: onFill) {
                Text("Fill")
                    .brandButton(.filledCapsule, isEnabled: fillEnabled)
            }
        }
        .padding()
        .background(Color(.systemBackground).ignoresSafeArea(edges: .bottom))
    }
}
