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
    let onCancel: () -> Void

    var body: some View {
        HStack {
            Button("Cancel", action: onCancel)
                .foregroundColor(.blue)
            Spacer()
            Text(title)
                .font(.headline)
            Spacer()
            Color.clear.frame(width: 60, height: 1)
        }
        .padding()
        .background(Color.white)
    }
}
