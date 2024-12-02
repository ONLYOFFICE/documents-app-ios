//
//  StorageQuotaSection.swift
//  Documents-opensource
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
                footer: Text(
                    NSLocalizedString("Storage quota set per room. You can change this value or turn off storage limit.", comment: "")
                )
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
            Text(NSLocalizedString("Storage quota", comment: ""))
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    @ViewBuilder
    private var sizeQuotaCell: some View {
        if viewModel.isStorateQuotaEnabled {
            HStack {
                Text(NSLocalizedString("Size quota", comment: ""))
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
                    Text(NSLocalizedString("Measurement unit", comment: ""))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(viewModel.selectedSizeUnit.localizedDesc)
                        .foregroundColor(.gray)
                    ChevronUpDownView()
                }
            }
        }
    }
}
