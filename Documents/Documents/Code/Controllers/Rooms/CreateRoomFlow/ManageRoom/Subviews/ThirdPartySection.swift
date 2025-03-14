//
//  ThirdPartySection.swift
//  Documents
//
//  Created by Pavel Chernyshev on 02.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ThirdPartySection: View {
    @ObservedObject var viewModel: ManageRoomViewModel

    var body: some View {
        if viewModel.selectedRoomType.type == .publicRoom && !viewModel.isEditMode {
            Section(
                footer: Text(
                    NSLocalizedString(
                        "Use third-party services as data storage for this room. A new folder for storing this room’s data will be created in the connected storage",
                        comment: ""
                    )
                )
            ) {
                thirdPartyToggleCell
                if viewModel.isThirdPartyStorageEnabled {
                    storageSelectionCell
                    folderSelectionCell
                    createNewFolderCell
                }
            }
        }
    }
}

// MARK: - Subviews

extension ThirdPartySection {
    private var thirdPartyToggleCell: some View {
        Toggle(isOn: Binding(
            get: { viewModel.isThirdPartyStorageEnabled },
            set: { viewModel.didTapThirdPartyStorageSwitch(isOn: $0) }
        )) {
            Text("Third party storage")
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    private var storageSelectionCell: some View {
        HStack(spacing: 4) {
            Text("Storage")
            Spacer()
            Text(verbatim: viewModel.selectedStorage ?? "")
                .foregroundColor(.gray)
            ChevronRightView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTapStorageSelectionCell()
        }
    }

    private var folderSelectionCell: some View {
        HStack {
            Text("Location")
            Spacer()
            Text(verbatim: viewModel.selectedLocation)
                .foregroundColor(.gray)
            ChevronRightView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTapSelectedFolderCell()
        }
    }

    private var createNewFolderCell: some View {
        Toggle(isOn: $viewModel.isCreateNewFolderEnabled) {
            Text("Create new folder")
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }
}
