//
//  WatermarkImageEditorView.swift
//  Documents
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
                footer: Text("This image preview roughly shows how the watermark will be displayed in your files.")
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
                Text("Scale")
                    .foregroundColor(.primary)
                Spacer()
                Text(verbatim: viewModel.selectedWatermarkImageScale.localizedDesc)
                    .foregroundColor(.gray)
                ChevronUpDownView()
            }
        }
    }

    private var rotateCell: some View {
        MenuView(menuItems: viewModel.watermarkImageRotationMenuItems) {
            HStack {
                Text("Rotate")
                    .foregroundColor(.primary)
                Spacer()
                Text(verbatim: viewModel.selectedWatermarkImageRotationAngle.localizedDesc)
                    .foregroundColor(.gray)
                ChevronUpDownView()
            }
        }
    }

    private var deleteCell: some View {
        HStack {
            Text("Remove")
                .foregroundColor(.red)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTapRemoveWatemarkImage()
        }
    }
}
