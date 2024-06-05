//
//  SharedSettingsView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 01.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct SharedSettingsView: View {
    @ObservedObject var viewModel: SharedSettingsViewModel

    var body: some View {
        List {
            if viewModel.isShared {
                sharedLinkSection
            } else {
                createAndCopySection
            }
        }
        .navigationBarTitle(Text(NSLocalizedString("Sharing settings", comment: "")), displayMode: .inline)
    }
    
    @ViewBuilder
    private var createAndCopySection: some View {
        Section(
            header: Text(NSLocalizedString("Shared links", comment: "")),
            footer: Text(NSLocalizedString("Provide access to the document and set the permission levels.", comment: ""))
        ) {
            ASCCreateLinkCellView(model:ASCCreateLinkCellModel(
                textString: NSLocalizedString("Create and copy", comment: ""),
                imageNames: [],
                onTapAction: viewModel.createAndCopySharedLink)
            )
        }
    }

    @ViewBuilder
    private var sharedLinkSection: some View {
        Section(
            header: Text(NSLocalizedString("Shared links", comment: "")),
            footer: Text(NSLocalizedString("Provide access to the document and set the permission levels.", comment: ""))
        ) {
            ForEach(viewModel.links) { linkModel in
                SharedSettingsLinkRow(model: linkModel)
            }
        }
    }
}
