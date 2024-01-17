//
//  RoomSharingCustomizeLinkView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import SwiftUI

struct RoomSharingCustomizeLinkView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: RoomSharingCustomizeLinkViewModel

    var body: some View {
        handleHUD()

        return content
            .navigationBarItems(rightBtn: shareButton)
            .disabledIfDeleting(viewModel.isDeleting)
            .alertForErrorMessage($viewModel.errorMessage)
            .dismissOnChange(of: viewModel.isDeleted, using: presentationMode)
            .sharingSheet(isPresented: $viewModel.isSharingScreenPresenting, link: viewModel.sharingLink)
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
            deleteSection
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
            Toggle(isOn: $viewModel.isProtected.animation()) {
                Text(NSLocalizedString("Password access", comment: ""))
            }
            .tintColor(Color(Asset.Colors.brend.color))
            .foregroundColor(.primary)

            if viewModel.isProtected {
                PasswordCellView(
                    model: PasswordCellModel(
                        password: $viewModel.password,
                        isPasswordVisible: $viewModel.isPasswordVisible
                    )
                )
                .foregroundColor(.primary)
            }
        }
    }

    private var timeLimitSection: some View {
        Section(
            header: Text(NSLocalizedString("Time limit", comment: "")),
            footer: viewModel.isExpired 
                ? Text(NSLocalizedString("The link has expired and has been disabled", comment: ""))
                    .foregroundColor(.red)
                : nil
        ) {
            Toggle(isOn: $viewModel.isTimeLimited.animation()) {
                Text(NSLocalizedString("Enable time limit", comment: ""))
            }
            .tintColor(Color(Asset.Colors.brend.color))

            if viewModel.isTimeLimited {
                TimeLimitCellView(model: TimeLimitCellModel(
                    selectedDate: $viewModel.selectedDate,
                    title: NSLocalizedString("Valid through", comment: "")
                ))
            }
        }
    }

    @ViewBuilder
    private var copySection: some View {
        if !viewModel.isExpired {
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
    }

    private var restrictionSection: some View {
        Section(footer: Text(NSLocalizedString("Enable this setting to disable downloads of files and folders from this room shared via a link", comment: ""))) {
            Toggle(isOn: $viewModel.isRestrictCopyOn) {
                Text(NSLocalizedString("Restrict file content copy, file download and printing", comment: ""))
            }
            .tintColor(Color(Asset.Colors.brend.color))
        }
    }

    @ViewBuilder
    private var deleteSection: some View {
        if viewModel.isDeletePossible {
            Section {
                ASCLabledCellView(
                    model: ASCLabledCellModel(
                        textString: NSLocalizedString("Delete link", comment: ""),
                        cellType: .deletable,
                        textAlignment: .center,
                        onTapAction: viewModel.onDelete
                    )
                )
            }
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if viewModel.sharingLink != nil {
            Button(
                NSLocalizedString("Share", comment: ""),
                action: {
                    viewModel.isSharingScreenPresenting = true
                }
            )
        }
    }

    private func handleHUD() {
        if viewModel.isDeleting {
            MBProgressHUD.currentHUD?.hide(animated: false)
            let hud = MBProgressHUD.showTopMost()
            hud?.mode = .indeterminate
            hud?.label.text = NSLocalizedString("Removing", comment: "") + "..."
        } else {
            if let hud = MBProgressHUD.currentHUD {
                if let resultModalModel = viewModel.resultModalModel {
                    switch resultModalModel.result {
                    case .success:
                        hud.setState(result: .success(NSLocalizedString("Deleted", comment: "")))
                    case .failure:
                        hud.setState(result: .failure(resultModalModel.message))
                    }

                    hud.hide(animated: true, afterDelay: resultModalModel.hideAfter)
                } else {
                    hud.hide(animated: true)
                }
            }
        }
    }
}

// MARK: Modifiers

private extension View {
    func navigationBarItems(rightBtn: some View) -> some View {
        navigationBarItems(trailing: rightBtn)
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

    func sharingSheet(isPresented: Binding<Bool>, link: URL?) -> some View {
        sheet(isPresented: isPresented) {
            if let link {
                ActivityView(activityItems: [link])
            }
        }
    }
}

#Preview {
    RoomSharingCustomizeLinkView(
        viewModel: .init(
            room: .init(),
            inputLink: nil,
            outputLink: .constant(nil)
        )
    )
}
