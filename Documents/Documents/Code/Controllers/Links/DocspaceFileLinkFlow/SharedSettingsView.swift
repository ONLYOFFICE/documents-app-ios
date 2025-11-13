//
//  SharedSettingsView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 01.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct SharedSettingsView: View {
    @ObservedObject var viewModel: SharedSettingsViewModel

    var body: some View {
        NavigationView {
            screenView
                .navigationBarTitle(Text("Sharing settings"), displayMode: .inline)
                .navigateToEditSharedLink(selectedLink: $viewModel.selectdLink, viewModel: viewModel)
                .sharingSheet(isPresented: $viewModel.isSharingScreenPresenting, link: viewModel.sharingLink)
        }
    }

    @ViewBuilder
    private var screenView: some View {
        List {
            if viewModel.isShared {
                sharedLinkSection
            } else {
                createAndCopySection
            }
        }
    }

    @ViewBuilder
    private var createAndCopySection: some View {
        Section(
            header: Text("Shared links"),
            footer: Text("Provide access to the document and set the permission levels.")
        ) {
            ASCCreateLinkCellView(
                model: ASCCreateLinkCellModel(
                    textString: NSLocalizedString("Create and copy", comment: ""),
                    imageNames: [],
                    onTapAction: viewModel.createAndCopySharedLink
                )
            )
        }
    }

    @ViewBuilder
    private var sharedLinkSection: some View {
        Section(
            header: sharedLinksSectionHeader,
            footer: Text("Provide access to the document and set the permission levels.")
        ) {
            ForEach(viewModel.links) { linkModel in
                SharedSettingsLinkRow(model: linkModel)
            }
        }
    }

    private var sharedLinksSectionHeader: some View {
        HStack {
            Text("Shared links")
            Text(verbatim: "(\(viewModel.links.count)/\(viewModel.linksLimit))")
            Spacer()
            if viewModel.links.count < viewModel.linksLimit {
                Button {
                    viewModel.addLink()
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Asset.Colors.brend.swiftUIColor)
                }
            }
        }
    }
}

extension View {
    func navigateToEditSharedLink(
        selectedLink: Binding<SharedSettingsLinkResponceModel?>, viewModel: SharedSettingsViewModel
    ) -> some View {
        navigation(item: selectedLink) { link in
            EditFileSharedLinkView(
                viewModel: EditFileSharedLinkViewModel(
                    file: viewModel.file,
                    inputLink: link,
                    outputLink: Binding(
                        get: { nil },
                        set: { newLink in
                            if let newLink {
                                viewModel.handleLinkOutChanges(link: newLink)
                            }
                        }
                    ),
                    onRemoveCompletion: {
                        viewModel.loadLinks()
                    }
                )
            )
        }
    }
}
