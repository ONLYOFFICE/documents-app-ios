//
//  WatermarkImageEditorView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 02.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct WatermarkImageEditorView: View {
    
    private func imageCell(image: UIImage) -> some View {
        VStack {
            Image(uiImage: viewModel.watermarkImage ?? UIImage())
                .resizable()
                .scaledToFit()
                .scaleEffect(viewModel.selectedWatermarkImageScale.rawValue / 100)
                .rotationEffect(.degrees(viewModel.selectedWatermarkImageRotationAngle.rawValue))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondaryLabel, lineWidth: 1)
                )
        }
    }

    private var scaleCell: some View {
        MenuView(menuItems: viewModel.watermarkImageScaleMenuItems) {
            HStack {
                Text(NSLocalizedString("Scale", comment: ""))
                    .foregroundColor(.primary)
                Spacer()
                Text(viewModel.selectedWatermarkImageScale.localizedDesc)
                    .foregroundColor(.gray)
                ChevronUpDownView()
            }
        }
    }
}
