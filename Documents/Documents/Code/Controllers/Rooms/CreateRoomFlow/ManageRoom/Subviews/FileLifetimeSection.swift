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
                footer: Text("Set file lifetime to automatically delete the files in this room after a defined period. Lifetime begins on the date of upload/creation of the file.")
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
            Text("File lifetime")
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }

    @ViewBuilder
    private var filesOlderThanCell: some View {
        if viewModel.isFileLifetimeEnabled {
            HStack {
                Text("Files older than")
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
                    Text("Time period")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(verbatim: viewModel.selectedTemePeriod.localizedDesc)
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
                    Text("Action on files")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(verbatim: viewModel.actionOnFiles.localizedDesc)
                        .foregroundColor(.gray)
                    ChevronUpDownView()
                }
            }
        }
    }
}
