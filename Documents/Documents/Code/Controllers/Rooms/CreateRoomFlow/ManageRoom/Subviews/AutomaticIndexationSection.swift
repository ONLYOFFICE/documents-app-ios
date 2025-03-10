//
//  AutomaticIndexationSection.swift
//  Documents
//
//  Created by Pavel Chernyshev on 02.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct AutomaticIndexationSection: View {
    @ObservedObject var viewModel: ManageRoomViewModel

    var body: some View {
        if viewModel.selectedRoomType.type == .virtualData {
            Section(
                footer: Text("Enable automatic indexing to index files and folders by serial number. Sorting by number will be set as default for all users.")
            ) {
                automaticIndexingCell
            }
        }
    }
}

// MARK: - Subviews

extension AutomaticIndexationSection {
    private var automaticIndexingCell: some View {
        Toggle(isOn: $viewModel.isAutomaticIndexing) {
            Text("Automatic indexing")
        }
        .tintColor(Color(Asset.Colors.brend.color))
    }
}
