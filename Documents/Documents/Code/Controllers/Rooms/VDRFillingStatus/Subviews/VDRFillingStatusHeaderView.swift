//
//  VDRFillingStatusHeaderView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 6.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct VDRFillingStatusHeaderView: View {
    let title: String
    let subtitle: String
    var isReady: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            if isReady {
                Asset.Images.checkmarkGreenCircle.swiftUIImage
                    .resizable()
                    .frame(width: 64, height: 64)
                    .padding(.bottom, 20)
            }
            VStack(spacing: 9) {
                Text(verbatim: title)
                    .font(.title2)
                    .foregroundColor(.primary)

                Text(verbatim: subtitle)
                    .font(.caption)
                    .foregroundColor(.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 18)
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 16)
    }
}
