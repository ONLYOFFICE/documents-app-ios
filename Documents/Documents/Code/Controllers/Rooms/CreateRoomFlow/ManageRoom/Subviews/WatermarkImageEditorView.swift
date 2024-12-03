//
//  WatermarkImageEditorView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 02.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct WatermarkImageEditorView: View {
    @ObservedObject var viewModel: ManageRoomViewModel

    var body: some View {
        if viewModel.selectedWatermarkType == .image, let image = viewModel.watermarkImage {
            Section(
                footer: Text(NSLocalizedString("This image preview roughly shows how the watermark will be displayed in your files.", comment: ""))
            ) {
                imageCell(image: image)
                scaleCell
                rotateCell
                deleteCell
            }
        }
    }

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

    private var rotateCell: some View {
        MenuView(menuItems: viewModel.watermarkImageRotationMenuItems) {
            HStack {
                Text(NSLocalizedString("Rotate", comment: ""))
                    .foregroundColor(.primary)
                Spacer()
                Text(viewModel.selectedWatermarkImageRotationAngle.localizedDesc)
                    .foregroundColor(.gray)
                ChevronUpDownView()
            }
        }
    }

    private var deleteCell: some View {
        HStack {
            Text(
                NSLocalizedString("Remove", comment: "")
            )
            .foregroundColor(.red)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTapRemoveWatemarkImage()
        }
    }
}
