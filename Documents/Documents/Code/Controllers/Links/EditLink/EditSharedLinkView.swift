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
            linkLifeTimeCell
        }
    }

    private var accessCell: some View {
        MenuView(menuItems: viewModel.accessMenuItems) {
            ASCDetailedChevronUpDownCellView(model: ASCDetailedChevronUpDownCellViewModel(
                title: NSLocalizedString("Access rights", comment: ""),
                detail: viewModel.selectedAccessRight.title()
            ))
        }
    }

    @ViewBuilder
    private var linkLifeTimeCell: some View {
        MenuView(menuItems: viewModel.linkLifeTimeMenuItems) {
            ASCDetailedChevronUpDownCellView(model: ASCDetailedChevronUpDownCellViewModel(
                title: NSLocalizedString("Link life time", comment: ""),
                detail: viewModel.expirationDateString
            ))
        }
        if viewModel.selectedLinkLifeTimeOption == .custom {
            validThrowCell
        }
    }

    private var validThrowCell: some View {
        TimeLimitCellView(model: TimeLimitCellModel(
            selectedDate: $viewModel.selectedDate,
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
                onTapAction: {
                    if viewModel.linkAccess == .docspaceUserOnly {
                        viewModel.setLinkType()
                    } else {
                        return
                    }
                }
            ))
            CheckmarkCellView(model: CheckmarkCellViewModel(
                text: NSLocalizedString("DoсSpace users only", comment: ""),
                isChecked: viewModel.linkAccess == .docspaceUserOnly,
                onTapAction: {
                    if viewModel.linkAccess == .anyoneWithLink {
                        viewModel.setLinkType()
                    } else {
                        return
                    }
                }
            ))
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
                    viewModel.removeLink()
                }
            ))
        }
    }
}
