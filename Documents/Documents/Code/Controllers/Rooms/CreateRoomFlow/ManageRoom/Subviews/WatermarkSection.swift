//
//  WatermarkSection.swift
//  Documents
//
//  Created by Pavel Chernyshev on 02.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct WatermarkSection: View {
    @ObservedObject var viewModel: ManageRoomViewModel

    var body: some View {
        if viewModel.selectedRoomType.type == .virtualData {
            Section(
                footer: !viewModel.isWatermarkEnabled || viewModel.selectedWatermarkType == .image
                    ? AnyView(Text("Protect all documents in this room with watermarks. If a document already contains one, it will not be replaced."))
                    : AnyView(EmptyView())
            ) {
                watermarkToggleCell
                watermarkTypeCell
                selectImageCell
            }

            watermarkElementsSection
            watermarkStaticTextSection
            watermarkPositionSection

            watermarkImageSection
        }
    }
}

// MARK: - Subviews

extension WatermarkSection {
    private var watermarkToggleCell: some View {
        Toggle(isOn: $viewModel.isWatermarkEnabled) {
            Text("Add watermarks to documents")
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    @ViewBuilder
    private var watermarkTypeCell: some View {
        if viewModel.isWatermarkEnabled {
            HStack {
                Text("Watermark type")
                Spacer()
                MenuView(menuItems: viewModel.watermarkTypeMenuItems) {
                    HStack {
                        Text(verbatim: viewModel.selectedWatermarkType.localizedDesc)
                            .foregroundColor(.gray)
                        ChevronUpDownView()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var selectImageCell: some View {
        if viewModel.isWatermarkEnabled, viewModel.selectedWatermarkType == .image {
            HStack {
                Text("Select image")
                    .foregroundColor(Color(Asset.Colors.brend.color))
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.didTapWatermarkImage()
            }
        }
    }

    @ViewBuilder
    private var watermarkImageSection: some View {
        WatermarkImageEditorView(viewModel: viewModel)
    }

    @ViewBuilder
    private var watermarkElementsSection: some View {
        if viewModel.isWatermarkEnabled, viewModel.selectedWatermarkType == .viewerInfo {
            Section(header: Text("Add watermark elements")) {
                ToggleButtonCollectionView(
                    buttonModels: viewModel.watermarkElementButtons,
                    width: UIScreen.main.bounds.width - 4 * 20
                )
                .contentShape(Rectangle())
                .padding(.top, 4)
            }
            .listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 20))
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var watermarkStaticTextSection: some View {
        if viewModel.isWatermarkEnabled, viewModel.selectedWatermarkType == .viewerInfo {
            Section {
                HStack {
                    TextField(NSLocalizedString("Add static text", comment: ""), text: $viewModel.watermarkStaticText)
                        .foregroundColor(.gray)
                        .disabled(viewModel.isSaving)
                }
            }
        }
    }

    @ViewBuilder
    private var watermarkPositionSection: some View {
        if viewModel.isWatermarkEnabled, viewModel.selectedWatermarkType == .viewerInfo {
            Section(
                footer: Text(
                    NSLocalizedString("Protect all documents in this room with watermarks. If a document already contains one, it will not be replaced.", comment: "")
                )
            ) {
                HStack {
                    Text("Position")
                    Spacer()
                    MenuView(menuItems: viewModel.watermarkPositionMenuItems) {
                        HStack {
                            Text(verbatim: viewModel.selectedWatermarkPosition.localizedDesc)
                                .foregroundColor(.gray)
                            ChevronUpDownView()
                        }
                    }
                }
            }
        }
    }
}
