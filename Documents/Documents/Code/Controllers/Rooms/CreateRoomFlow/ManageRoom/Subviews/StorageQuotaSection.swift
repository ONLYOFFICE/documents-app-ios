//
//  StorageQuotaSection.swift
//  Documents
//
//  Created by Pavel Chernyshev on 02.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct StorageQuotaSection: View {
    @ObservedObject var viewModel: ManageRoomViewModel

    var body: some View {
        if viewModel.allowChangeStorageQuota {
            Section(
                footer: Text("Storage quota set per room. You can change this value or turn off storage limit.")
            ) {
                storageQuotaCell
                sizeQuotaCell
                quotaSizeUnitCell
            }
        }
    }
}

// MARK: - Subviews

extension StorageQuotaSection {
    private var storageQuotaCell: some View {
        Toggle(isOn: $viewModel.isStorateQuotaEnabled) {
            Text("Storage quota")
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    @ViewBuilder
    private var sizeQuotaCell: some View {
        if viewModel.isStorateQuotaEnabled {
            HStack {
                Text("Size quota")
                Spacer()
                TextField("", value: $viewModel.sizeQuota, formatter: viewModel.sizeQuotaFormatter)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            }
        }
    }

    @ViewBuilder
    private var quotaSizeUnitCell: some View {
        if viewModel.isStorateQuotaEnabled {
            MenuView(menuItems: viewModel.quotaSizeUnitMenuItems) {
                HStack {
                    Text("Measurement unit")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(verbatim: viewModel.selectedSizeUnit.localizedDesc)
                        .foregroundColor(.gray)
                    ChevronUpDownView()
                }
            }
        }
    }
}
