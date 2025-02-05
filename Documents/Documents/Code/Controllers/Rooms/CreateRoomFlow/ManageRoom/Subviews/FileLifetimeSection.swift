//
//  FileLifetimeSection.swift
//  Documents
//
//  Created by Pavel Chernyshev on 02.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct FileLifetimeSection: View {
    @ObservedObject var viewModel: ManageRoomViewModel

    var body: some View {
        if viewModel.selectedRoomType.type == .virtualData {
            Section(
                footer: Text(
                    NSLocalizedString("Set file lifetime to automatically delete the files in this room after a defined period. Lifetime begins on the date of upload/creation of the file.", comment: "")
                )
            ) {
                filesLifetimeCell
                filesOlderThanCell
                filesTimePeriodCell
                actionOnFilesCell
            }
        }
    }
}

// MARK: - Subviews

extension FileLifetimeSection {
    private var filesLifetimeCell: some View {
        Toggle(isOn: $viewModel.isFileLifetimeEnabled) {
            Text(NSLocalizedString("File lifetime", comment: ""))
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    @ViewBuilder
    private var filesOlderThanCell: some View {
        if viewModel.isFileLifetimeEnabled {
            HStack {
                Text(NSLocalizedString("Files older than", comment: ""))
                Spacer()
                TextField("", value: $viewModel.fileAge, formatter: viewModel.fileAgeNumberFormatter)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            }
        }
    }

    @ViewBuilder
    private var filesTimePeriodCell: some View {
        if viewModel.isFileLifetimeEnabled {
            MenuView(menuItems: viewModel.filesTimePeriodMenuItems) {
                HStack {
                    Text(NSLocalizedString("Time period", comment: ""))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(viewModel.selectedTemePeriod.localizedDesc)
                        .foregroundColor(.gray)
                    ChevronUpDownView()
                }
            }
        }
    }

    @ViewBuilder
    private var actionOnFilesCell: some View {
        if viewModel.isFileLifetimeEnabled {
            MenuView(menuItems: viewModel.actionOnFilesMenuItems) {
                HStack {
                    Text(NSLocalizedString("Action on files", comment: ""))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(viewModel.actionOnFiles.localizedDesc)
                        .foregroundColor(.gray)
                    ChevronUpDownView()
                }
            }
        }
    }
}
