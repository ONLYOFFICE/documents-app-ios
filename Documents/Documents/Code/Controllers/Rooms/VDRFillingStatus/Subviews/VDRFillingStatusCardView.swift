//
//  VDRFillingStatusCardView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 10.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

/// Card view displaying application info
struct VDRFillingStatusCardView: View {
    let application: VDRFillingStatusApplicationModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(application.title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(application.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(application.status.label)
                .font(.caption2.bold())
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(application.status.color.opacity(0.2))
                .foregroundColor(application.status.color)
                .cornerRadius(8)
        }
        .padding()
        .modifier(CardStyle())
    }
}
