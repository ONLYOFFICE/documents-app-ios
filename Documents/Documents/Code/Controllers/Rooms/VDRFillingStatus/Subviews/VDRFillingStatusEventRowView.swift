//
//  VDRFillingStatusEventRowView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 7.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

/// Row view for a single timeline event
struct VDRFillingStatusEventRowView: View {
    let event: VDRFillingStatusEvent
    let showConnector: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Text("\(event.number)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if showConnector {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 2, height: 40)
                }
            }

            Image(systemName: event.status.iconName)
                .font(.title3)
                .foregroundColor(event.status.iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.actor)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                if let desc = event.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(event.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.white)
        .modifier(CardStyle(cornerRadius: 12))
    }
}
