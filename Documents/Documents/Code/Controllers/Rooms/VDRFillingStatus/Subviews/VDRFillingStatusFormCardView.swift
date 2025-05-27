//
//  VDRFillingStatusFormCardView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 10.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

/// Card view displaying application info
struct VDRFillingStatusFormCardView: View {
    let formModel: VDRFillingStatusFormInfoModel

    var body: some View {
        HStack(spacing: 12) {
            Asset.Images.listFormatPdf.swiftUIImage
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(verbatim: formModel.title)
                        .font(.footnote)
                        .fontWeight(.semibold)
                    Text(verbatim: formModel.status.localizedString)
                        .font(.caption2.bold())
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background(formModel.status.color)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }

                Text(verbatim: formModel.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(verbatim: formModel.detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .modifier(CardStyle())
    }
}
