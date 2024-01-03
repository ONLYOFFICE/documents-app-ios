//
//  RoomSharingCustomizeLinkView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct RoomSharingCustomizeLinkView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: RoomSharingCustomizeLinkViewModel

    var body: some View {
        content
            .navigationBarItems()
            .disabledIfDeleting(viewModel.isDeleting)
            .overlay(deletingRoomActivityView)
            .overlay(resultModalView)
            .alertForErrorMessage($viewModel.errorMessage)
            .dismissOnChange(of: viewModel.isDeleted, using: presentationMode)
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

    var generalLinkView: some View {
        List {
            generalSection
            protectedSection
            restrictionSection
        }
        .navigationBarTitle(Text(NSLocalizedString("General link", comment: "")))
    }

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
            TextField("Link name", text: $viewModel.linkName)
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
                    PasswordCellView(
                        model: PasswordCellModel(
                            password: $viewModel.password,
                            isPasswordVisible: $viewModel.isPasswordVisible
                        )
                    )
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
                TimeLimitCellView(model: TimeLimitCellModel(
                    selectedDate: $viewModel.selectedDate,
                    title: NSLocalizedString("Valid through", comment: "")
                ))
            }
        }
    }

    private var copySection: some View {
        Section {
            ASCLabledCellView(model:
                .init(
                    textString: NSLocalizedString(viewModel.isProtected ? "Copy link and password" : "Copy link", comment: ""),
                    cellType: .standard,
                    textAlignment: .center,
                    onTapAction: viewModel.onCopyLinkAndNotify
                )
            )
            .disabled(viewModel.linkName.isEmpty)
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
            ASCLabledCellView(
                model: ASCLabledCellModel(
                    textString: NSLocalizedString("Delete link", comment: ""),
                    cellType: .deletable,
                    textAlignment: .center,
                    onTapAction: {
                        viewModel.onDelete()
                    }
                )
            )
        }
    }

    @ViewBuilder
    private var deletingRoomActivityView: some View {
        if viewModel.isDeleting {
            MBProgressHUDView(
                isLoading: $viewModel.isDeleting,
                text: NSLocalizedString("Removing...", comment: ""),
                delay: 0.3,
                successStatusText: viewModel.isDeleted ? NSLocalizedString("Deleted", comment: "") : nil
            )
        }
    }

    private var resultModalView: some View {
        ResultModalView(model: $viewModel.resultModalModel)
    }
}

// MARK: Modifiers

private extension View {
    func navigationBarItems() -> some View {
        navigationBarItems(trailing: Button(NSLocalizedString("Share", comment: ""), action: {}))
    }

    func disabledIfDeleting(_ isDeleting: Bool) -> some View {
        disabled(isDeleting)
    }

    func alertForErrorMessage(_ errorMessage: Binding<String?>) -> some View {
        alert(item: errorMessage) { message in
            Alert(
                title: Text(NSLocalizedString("Error", comment: "")),
                message: Text(message),
                dismissButton: .default(Text("OK"), action: {
                    errorMessage.wrappedValue = nil
                })
            )
        }
    }

    func dismissOnChange(of value: Bool, using presentationMode: Binding<PresentationMode>) -> some View {
        onChange(of: value) { newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ASCDocSpaceLinkSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        RoomSharingCustomizeLinkView(viewModel: .init(room: .init(), inputLink: nil, outputLink: .constant(nil)))
    }
}
