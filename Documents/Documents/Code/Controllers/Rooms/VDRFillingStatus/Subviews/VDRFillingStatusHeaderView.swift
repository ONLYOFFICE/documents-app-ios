//
//  VDRFillingStatusHeaderView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 6.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

/// Header with title and cancel action
struct VDRFillingStatusHeaderView: View {
    let title: String
    let subtitle: String
    let onCancel: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button(NSLocalizedString("Cancel", comment: ""), action: onCancel)
                    .foregroundColor(Color(.systemBlue))
                Spacer()
                Text(verbatim: title)
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 60, height: 1)
            }
            .padding()
            .background(Color(.systemBackground))

            HStack {
                Text(verbatim: subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }.padding()
        }
    }
}
