//
//  RestrictContentCopySection.swift
//  Documents
//
//  Created by Pavel Chernyshev on 02.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct RestrictContentCopySection: View {
    @ObservedObject var viewModel: ManageRoomViewModel

    var body: some View {
        if viewModel.selectedRoomType.type == .virtualData {
            Section(
                footer: Text(
                    NSLocalizedString(
                        "Enable this setting to disable downloads, printing, and content copying for users with the “Viewer” role",
                        comment: ""
                    )
                )
            ) {
                Toggle(isOn: $viewModel.isRestrictContentCopy) {
                    Text(NSLocalizedString("Restrict file content copy, file download and printing", comment: ""))
                }
                .tintColor(Color(Asset.Colors.brend.color))
            }
        }
    }
}
