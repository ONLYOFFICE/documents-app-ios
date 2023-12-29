//
//  RoomSharingCustomizeLinkView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct RoomSharingCustomizeLinkView: View {
    @ObservedObject var viewModel: RoomSharingCustomizeLinkViewModel

    var body: some View {
        content
            .navigationBarItems(
                trailing: Button(NSLocalizedString("Share", comment: ""), action: {})
            )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.contentState {
        case .general:
            generalLinkView
        case .additional:
            additionalLinkView
        }
    }

    @ViewBuilder
    var generalLinkView: some View {
        List {
            generalSection
            protectedSection
            restrictionSection
        }
        .navigationBarTitle(Text(NSLocalizedString("General link", comment: "")))
    }

    @ViewBuilder
    var additionalLinkView: some View {
        List {
            generalSection
            protectedSection
            restrictionSection
            timeLimitSection
            copySection
            deleteSection
        }
        .navigationBarTitle(Text(NSLocalizedString("Additional links", comment: "")))
    }

    private var generalSection: some View {
        Section(header: Text(NSLocalizedString("General", comment: ""))) {
            Text(viewModel.link?.linkInfo.title ?? "")
        }
    }

    private var protectedSection: some View {
        Section(header: Text(NSLocalizedString("Protection", comment: ""))) {
            VStack {
                Toggle(isOn: $viewModel.isProtected) {
                    Text(NSLocalizedString("Password access", comment: ""))
                }

                if viewModel.isProtected {
                    Divider()
                    PasswordCellView(model: .init(password: viewModel.password, isPasswordVisible: false))
                }
            }
        }
    }

    private var timeLimitSection: some View {
        Section(header: Text(NSLocalizedString("Time limit", comment: ""))) {
            Toggle(isOn: $viewModel.isTimeLimited) {
                Text(NSLocalizedString("Enable time limit", comment: ""))
            }
            if viewModel.isTimeLimited {
                TimeLimitCellView(model: .init(title: NSLocalizedString("Valid through", comment: "")))
            }
        }
    }

    private var copySection: some View {
        Section {
            ASCLabledCellView(model: .init(
                textString: NSLocalizedString(viewModel.isProtected ? "Copy link and password" : "Copy link", comment: ""),
                cellType: .standard,
                textAlignment: .center,
                onTapAction: {}
            )
            )
        }
    }

    private var restrictionSection: some View {
        Section(footer: Text(NSLocalizedString("Enable this setting to disable downloads of files and folders from this room shared via a link", comment: ""))) {
            Toggle(isOn: $viewModel.isRestrictCopyOn) {
                Text(NSLocalizedString("Restrict file content copy, file download and printing", comment: ""))
            }
        }
    }

    private var deleteSection: some View {
        Section {
            ASCLabledCellView(model: .init(
                textString: NSLocalizedString("Delete link", comment: ""),
                cellType: .deletable,
                textAlignment: .center,
                onTapAction: {}
            )
            )
        }
    }
}

struct ASCDocSpaceLinkSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        RoomSharingCustomizeLinkView(viewModel: .init(link: nil))
    }
}
