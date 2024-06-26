//
//  EditSharedLinkView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 05.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct EditSharedLinkView: View {
    @ObservedObject var viewModel: EditSharedLinkViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            generalSection
            typeSection
            if viewModel.isExpired {
                regenerateLinkSection
            } else {
                copyLinkSection
            }
            removeLinkSection
        }
        .navigationBarTitle(Text(NSLocalizedString("Shared link", comment: "")), displayMode: .inline)
    }

    @ViewBuilder
    private var generalSection: some View {
        Section(
            header: Text(NSLocalizedString("General", comment: "")))
        {
            accessCell
                .disabled(viewModel.isExpired)
            linkLifeTimeCell
                .disabled(viewModel.isExpired)
        }
    }

    private var accessCell: some View {
        MenuView(menuItems: viewModel.accessMenuItems) {
            ASCDetailedChevronUpDownCellView(model: ASCDetailedChevronUpDownCellViewModel(
                title: NSLocalizedString("Access rights", comment: ""),
                detail: viewModel.selectedAccessRight.title(),
                isEnabled: !viewModel.isExpired
            ))
        }
    }

    @ViewBuilder
    private var linkLifeTimeCell: some View {
        MenuView(menuItems: viewModel.linkLifeTimeMenuItems) {
            ASCDetailedChevronUpDownCellView(model: ASCDetailedChevronUpDownCellViewModel(
                title: NSLocalizedString("Link life time", comment: ""),
                detail: viewModel.linkLifeTimeString,
                isEnabled: !viewModel.isExpired
            ))
        }
        if viewModel.selectedLinkLifeTimeOption == .custom {
            validThrowCell
        }
    }

    private var validThrowCell: some View {
        TimeLimitCellView(model: TimeLimitCellModel(
            selectedDate: Binding<Date>(
                get: { viewModel.selectedDate ?? Date() },
                set: {
                    viewModel.selectedDate = $0
                    viewModel.didDateChangedManualy()
                }
            ),
            title: NSLocalizedString("Valid through", comment: ""),
            displayedComponents: [.date]
        ))
    }

    @ViewBuilder
    private var typeSection: some View {
        Section(
            header: Text(NSLocalizedString("Type", comment: "")))
        {
            CheckmarkCellView(model: CheckmarkCellViewModel(
                text: NSLocalizedString("Anyone with the link", comment: ""),
                isChecked: viewModel.linkAccess == .anyoneWithLink,
                isEnabled: !viewModel.isExpired,
                onTapAction: {
                    if viewModel.linkAccess != .anyoneWithLink {
                        viewModel.setLinkType(linkAccess: .anyoneWithLink)
                    }
                }
            ))
            .disabled(viewModel.isExpired)
            CheckmarkCellView(model: CheckmarkCellViewModel(
                text: NSLocalizedString("DoсSpace users only", comment: ""),
                isChecked: viewModel.linkAccess == .docspaceUserOnly,
                isEnabled: !viewModel.isExpired,
                onTapAction: {
                    if viewModel.linkAccess != .docspaceUserOnly {
                        viewModel.setLinkType(linkAccess: .docspaceUserOnly)
                    }
                }
            ))
            .disabled(viewModel.isExpired)
        }
    }

    @ViewBuilder
    private var copyLinkSection: some View {
        Section {
            ASCLabledCellView(model: ASCLabledCellModel(
                textString: NSLocalizedString("Copy link", comment: ""),
                cellType: .standard,
                textAlignment: .center,
                onTapAction: {
                    viewModel.copyLink()
                }
            ))
        }
    }

    private var regenerateLinkSection: some View {
        Section {
            ASCLabledCellView(model: ASCLabledCellModel(
                textString: NSLocalizedString("Regenerate link", comment: ""),
                cellType: .standard,
                textAlignment: .center,
                onTapAction: {
                    viewModel.regenerateLink()
                }
            ))
        }
    }

    @ViewBuilder
    private var removeLinkSection: some View {
        Section {
            ASCLabledCellView(model: ASCLabledCellModel(
                textString: NSLocalizedString("Remove link", comment: ""),
                cellType: .deletable,
                textAlignment: .center,
                onTapAction: {
                    viewModel.removeLink {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            ))
        }
    }
}
