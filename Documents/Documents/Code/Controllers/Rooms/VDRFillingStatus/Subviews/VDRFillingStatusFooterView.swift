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
    let isReadyForFillingScreenStatus: Bool
    let fillingStatus: FormFillingStatus
    let onStop: () -> Void
    let onFill: () -> Void
    let onCopy: () -> Void
    let onGoToRoom: () -> Void

    var body: some View {
        VStack(spacing: .zero) {
            Rectangle()
                .fill(Color.secondary)
                .frame(height: 0.5)
            HStack {
                if isReadyForFillingScreenStatus {
                    Button("Go to room", action: onGoToRoom)
                        .brandButton(.inline)
                } else {
                    Button("Stop filling", action: onStop)
                        .brandButton(.inline)
                        .disabled(!stopEnabled)
                }

                Spacer()

                if isReadyForFillingScreenStatus, fillingStatus != .yourTurn {
                    Button("Copy link", action: onCopy)
                        .brandButton(.filledCapsule)
                } else {
                    Button("Fill", action: onFill)
                        .brandButton(.filledCapsule)
                        .disabled(!fillEnabled)
                }
            }
            .padding()
        }
        .background(Color(.tertiarySystemBackground).ignoresSafeArea(edges: .bottom))
    }
}
